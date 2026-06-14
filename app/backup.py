import os
import shutil
import threading
import time
import datetime
import json
import logging
import subprocess

from flask import (
    Blueprint,
    current_app,
    render_template,
    request,
    flash,
    redirect,
    url_for,
    send_from_directory,
    abort,
)
from flask.cli import with_appcontext
from sqlalchemy.engine.url import make_url
from sqlalchemy import MetaData, Table, text

from app.app import app, db
from app.auth import admin_required, admin_master_required


backup_bp = Blueprint("backup", __name__, url_prefix="/admin/backups")


# Diretório de backups (na raiz do projeto)
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKUP_DIR = os.path.join(ROOT, "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)

LOG_FILE = os.path.join(BACKUP_DIR, "backup.log")
logger = logging.getLogger("sxf_backup")
if not logger.handlers:
    fh = logging.FileHandler(LOG_FILE)
    fh.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    logger.addHandler(fh)
    logger.setLevel(logging.INFO)


def _now_str():
    return datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


def _is_sqlite(uri: str):
    return uri.startswith("sqlite:")


def _sqlite_path_from_uri(uri: str):
    # uri like sqlite:////abs/path or sqlite:///relative
    if uri.startswith("sqlite:///"):
        return uri.replace("sqlite:///", "")
    return uri


def make_backup():
    uri = current_app.config.get("SQLALCHEMY_DATABASE_URI")
    timestamp = _now_str()
    try:
        if _is_sqlite(uri):
            src = _sqlite_path_from_uri(uri)
            ext = os.path.splitext(src)[1] or ".sqlite"
            fname = f"backup_{timestamp}{ext}"
            dst = os.path.join(BACKUP_DIR, fname)
            shutil.copy2(src, dst)
            logger.info(f"SQLite backup created: {dst}")
            return True, fname

        # MySQL / other — prefer using mysqldump when available
        url = make_url(uri)
        fname_sql = f"backup_{timestamp}.sql"
        dst = os.path.join(BACKUP_DIR, fname_sql)

        # try mysqldump
        try:
            cmd = [
                "mysqldump",
                "-h", url.host or "localhost",
                "-P", str(url.port or 3306),
                "-u", url.username or "",
            ]
            if url.password:
                cmd.append(f"-p{url.password}")
            cmd.append(url.database)
            with open(dst, "wb") as f:
                subprocess.check_call(cmd, stdout=f)
            logger.info(f"MySQL backup via mysqldump created: {dst}")
            return True, fname_sql
        except Exception as e:
            logger.warning("mysqldump failed or not present, falling back to SQLAlchemy row export: %s", e)

        # fallback: export rows as JSON of table->rows
        meta = MetaData()
        meta.reflect(bind=db.engine)
        data = {}
        conn = db.engine.connect()
        for table in meta.sorted_tables:
            rows = [dict(r) for r in conn.execute(table.select()).mappings().fetchall()]
            data[table.name] = rows
        conn.close()
        fname_json = f"backup_{timestamp}.json"
        dst_json = os.path.join(BACKUP_DIR, fname_json)
        with open(dst_json, "w", encoding="utf-8") as f:
            json.dump({"meta": {"uri": uri}, "data": data}, f, default=str, ensure_ascii=False)
        logger.info(f"MySQL fallback (JSON) backup created: {dst_json}")
        return True, fname_json

    except Exception as e:
        logger.exception("Erro ao criar backup: %s", e)
        return False, str(e)


def list_backups():
    items = []
    for name in sorted(os.listdir(BACKUP_DIR), reverse=True):
        path = os.path.join(BACKUP_DIR, name)
        if not os.path.isfile(path):
            continue
        stat = os.stat(path)
        items.append({
            "name": name,
            "mtime": datetime.datetime.fromtimestamp(stat.st_mtime),
            "size": stat.st_size,
        })
    return items


def _safe_path(fname: str):
    # prevent path traversal
    ab = os.path.abspath(os.path.join(BACKUP_DIR, fname))
    if not ab.startswith(os.path.abspath(BACKUP_DIR)):
        raise ValueError("Nome de arquivo inválido")
    return ab


def restore_backup(fname: str):
    try:
        path = _safe_path(fname)
        uri = current_app.config.get("SQLALCHEMY_DATABASE_URI")
        if _is_sqlite(uri):
            db_path = _sqlite_path_from_uri(uri)
            # close sessions and dispose engine
            db.session.remove()
            db.engine.dispose()
            shutil.copy2(path, db_path)
            logger.info(f"Restaurado backup sqlite {path} -> {db_path}")
            return True, "Restauração SQLite concluída."

        # MySQL
        if fname.lower().endswith(".sql"):
            # try to run the SQL statements
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                sql = f.read()
            conn = db.engine.connect()
            trans = conn.begin()
            try:
                # execute raw SQL in chunks separated by ;
                for stmt in sql.split(";"):
                    s = stmt.strip()
                    if not s:
                        continue
                    conn.execute(text(s))
                trans.commit()
            except Exception as e:
                trans.rollback()
                logger.exception("Erro ao executar SQL de restauração: %s", e)
                return False, str(e)
            finally:
                conn.close()
            logger.info(f"Restauração MySQL via .sql concluída: {path}")
            return True, "Restauração MySQL (.sql) concluída."

        # json fallback: truncate and insert
        if fname.lower().endswith(".json"):
            with open(path, "r", encoding="utf-8") as f:
                payload = json.load(f)
            data = payload.get("data", {})
            meta = MetaData()
            meta.reflect(bind=db.engine)
            conn = db.engine.connect()
            trans = conn.begin()
            try:
                # disable foreign key checks if supported
                try:
                    conn.execute(text("SET FOREIGN_KEY_CHECKS=0;"))
                except Exception:
                    pass
                for tbl_name, rows in data.items():
                    table = Table(tbl_name, meta, autoload_with=db.engine)
                    conn.execute(table.delete())
                    if rows:
                        conn.execute(table.insert(), rows)
                try:
                    conn.execute(text("SET FOREIGN_KEY_CHECKS=1;"))
                except Exception:
                    pass
                trans.commit()
            except Exception as e:
                trans.rollback()
                logger.exception("Erro na restauração JSON: %s", e)
                return False, str(e)
            finally:
                conn.close()
            logger.info(f"Restauração MySQL via JSON concluída: {path}")
            return True, "Restauração via JSON concluída."

        return False, "Formato de backup desconhecido"
    except Exception as e:
        logger.exception("Erro ao restaurar backup: %s", e)
        return False, str(e)


@backup_bp.route("/")
@admin_required
def index():
    items = list_backups()
    return render_template("admin/backups.html", backups=items)


@backup_bp.route("/create", methods=["POST"])
@admin_required
def create():
    ok, info = make_backup()
    if ok:
        flash("Backup criado: %s" % info, "ok")
    else:
        flash("Erro ao criar backup: %s" % info, "erro")
    return redirect(url_for("backup.index"))


@backup_bp.route("/download/<path:filename>")
@admin_required
def download(filename):
    try:
        path = _safe_path(filename)
    except ValueError:
        abort(404)
    return send_from_directory(BACKUP_DIR, filename, as_attachment=True)


@backup_bp.route("/restore", methods=["POST"])
@admin_master_required
def restore():
    fname = request.form.get("filename")
    confirm = request.form.get("confirm")
    if not fname:
        flash("Arquivo não informado.", "erro")
        return redirect(url_for("backup.index"))
    # confirmação obrigatória: usuário deve digitar CONFIRMAR
    if (confirm or "").strip().upper() != "CONFIRMAR":
        flash("Confirmação inválida. Digite 'CONFIRMAR' para proceder.", "erro")
        return redirect(url_for("backup.index"))
    ok, info = restore_backup(fname)
    if ok:
        flash("Restauração concluída: %s" % info, "ok")
    else:
        flash("Erro na restauração: %s" % info, "erro")
    return redirect(url_for("backup.index"))


@backup_bp.route("/download-log")
@admin_required
def download_log():
    if os.path.exists(LOG_FILE):
        return send_from_directory(BACKUP_DIR, os.path.basename(LOG_FILE), as_attachment=True)
    abort(404)


@app.cli.command("backup-db")
@with_appcontext
def backup_db_command():
    """Gera backup imediato do banco de dados."""
    ok, info = make_backup()
    if ok:
        print("Backup criado:", info)
    else:
        print("Erro ao criar backup:", info)


def _daily_worker():
    # roda uma vez por dia, tentando criar backup por volta da mesma hora
    # espera até próxima execução (24h)
    while True:
        try:
            with app.app_context():
                ok, info = make_backup()
                if ok:
                    logger.info(f"Backup automático criado: {info}")
                else:
                    logger.error(f"Falha no backup automático: {info}")
        except Exception:
            logger.exception("Erro no worker de backup automático")
        # dormir 24h
        time.sleep(24 * 3600)


# inicializar worker em background (não em ambiente de testes)
try:
    if not app.config.get("TESTING"):
        t = threading.Thread(target=_daily_worker, daemon=True, name="backup-daily")
        t.start()
except Exception:
    logger.exception("Não foi possível iniciar worker de backup")
