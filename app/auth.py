from datetime import datetime, timedelta
from functools import wraps

from flask import Blueprint, flash, redirect, render_template, request, url_for
from flask_login import current_user, login_required, login_user, logout_user

from app.app import bcrypt, db
from app.models import Paciente, Role, Usuario

auth_bp = Blueprint("auth", __name__)


# ---------------------------------------------------------------------------
# Decoradores de papel
# ---------------------------------------------------------------------------
def admin_required(f):
    @wraps(f)
    @login_required
    def decorated(*args, **kwargs):
        if not current_user.is_admin:
            flash("Acesso restrito a administradores.", "erro")
            return redirect(url_for("pacientes_lista"))
        return f(*args, **kwargs)
    return decorated


def admin_master_required(f):
    @wraps(f)
    @login_required
    def decorated(*args, **kwargs):
        if not current_user.is_admin_master:
            flash("Acesso restrito ao administrador master.", "erro")
            return redirect(url_for("pacientes_lista"))
        return f(*args, **kwargs)
    return decorated


def profissional_required(f):
    """Bloqueia pacientes — apenas profissionais e admins podem acessar."""
    @wraps(f)
    @login_required
    def decorated(*args, **kwargs):
        if current_user.is_paciente:
            flash("Acesso restrito a profissionais de saúde.", "erro")
            return redirect(url_for("meu_historico"))
        return f(*args, **kwargs)
    return decorated


# ---------------------------------------------------------------------------
# Login / Logout
# ---------------------------------------------------------------------------
@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return _redirecionar_por_role(current_user)

    if request.method == "POST":
        cpf = request.form.get("cpf", "").strip()
        senha = request.form.get("senha", "")

        # Buscar paciente pelo CPF
        paciente = Paciente.query.filter_by(cpf=cpf, ativo=True).first()
        
        if not paciente:
            flash("CPF ou senha inválidos.", "erro")
            return render_template("login/login.html")
        
        # Buscar usuário vinculado ao paciente
        usuario = Usuario.query.filter_by(paciente_id=paciente.id).first()

        if not usuario or not usuario.ativo:
            flash("CPF ou senha inválidos.", "erro")
            return render_template("login/login.html")

        if usuario.esta_bloqueado():
            flash("Conta temporariamente bloqueada. Tente novamente mais tarde.", "erro")
            return render_template("login/login.html")

        if not bcrypt.check_password_hash(usuario.senha_hash, senha):
            usuario.tentativas_login += 1
            if usuario.tentativas_login >= 5:
                usuario.bloqueado_ate = datetime.utcnow() + timedelta(minutes=30)
                flash("Muitas tentativas. Conta bloqueada por 30 minutos.", "erro")
            else:
                flash(f"Senha incorreta. Tentativa {usuario.tentativas_login}/5.", "erro")
            db.session.commit()
            return render_template("login/login.html")

        usuario.tentativas_login = 0
        usuario.bloqueado_ate = None
        usuario.ultimo_login = datetime.utcnow()
        db.session.commit()

        login_user(usuario, remember=False)
        proximo = request.args.get("next")
        return redirect(proximo or _redirecionar_por_role(usuario).location)

    return render_template("login/login.html")


@auth_bp.route("/login2", methods=["GET", "POST"])
def login2():
    if current_user.is_authenticated:
        return _redirecionar_por_role(current_user)

    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        senha = request.form.get("senha", "")

        usuario = Usuario.query.filter_by(email=email).first()

        if not usuario or not usuario.ativo:
            flash("E-mail ou senha inválidos.", "erro")
            return render_template("login/login2.html")

        if usuario.esta_bloqueado():
            flash("Conta temporariamente bloqueada. Tente novamente mais tarde.", "erro")
            return render_template("login/login2.html")

        if not bcrypt.check_password_hash(usuario.senha_hash, senha):
            usuario.tentativas_login += 1
            if usuario.tentativas_login >= 5:
                usuario.bloqueado_ate = datetime.utcnow() + timedelta(minutes=30)
                flash("Muitas tentativas. Conta bloqueada por 30 minutos.", "erro")
            else:
                flash(f"Senha incorreta. Tentativa {usuario.tentativas_login}/5.", "erro")
            db.session.commit()
            return render_template("login/login2.html")

        usuario.tentativas_login = 0
        usuario.bloqueado_ate = None
        usuario.ultimo_login = datetime.utcnow()
        db.session.commit()

        login_user(usuario, remember=False)
        proximo = request.args.get("next")
        return redirect(proximo or _redirecionar_por_role(usuario).location)

    return render_template("login/login2.html")


@auth_bp.route("/logout")
@login_required
def logout():
    logout_user()
    flash("Você saiu do sistema.", "ok")
    return redirect(url_for("auth.login"))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _redirecionar_por_role(usuario):
    if usuario.role_id == Role.PACIENTE:
        return redirect(url_for("meu_historico"))
    return redirect(url_for("pacientes_lista"))
