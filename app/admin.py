from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.app import bcrypt, db
from app.auth import admin_master_required, admin_required
from app.models import Instituicao, Role, Usuario

admin_bp = Blueprint("admin", __name__, url_prefix="/admin")


# ---------------------------------------------------------------------------
# Usuários
# ---------------------------------------------------------------------------
@admin_bp.route("/usuarios")
@admin_required
def usuarios_lista():
    usuarios = Usuario.query.order_by(Usuario.nome_completo).all()
    return render_template("admin/usuarios_lista.html", usuarios=usuarios)


@admin_bp.route("/usuarios/novo", methods=["GET", "POST"])
@admin_required
def usuario_novo():
    roles = Role.query.all()
    instituicoes = Instituicao.query.filter_by(ativa=True).order_by(Instituicao.nome).all()

    if request.method == "POST":
        email = request.form["email"].strip().lower()
        if Usuario.query.filter_by(email=email).first():
            flash("Este e-mail já está cadastrado.", "erro")
            return render_template("admin/usuario_form.html", roles=roles, instituicoes=instituicoes, usuario=None)

        senha = request.form["senha"]
        if len(senha) < 6:
            flash("A senha deve ter pelo menos 6 caracteres.", "erro")
            return render_template("admin/usuario_form.html", roles=roles, instituicoes=instituicoes, usuario=None)

        inst_id = request.form.get("instituicao_id") or None
        if inst_id:
            inst_id = int(inst_id)

        usuario = Usuario(
            role_id=int(request.form["role_id"]),
            instituicao_id=inst_id,
            nome_completo=request.form["nome_completo"].strip(),
            email=email,
            senha_hash=bcrypt.generate_password_hash(senha).decode("utf-8"),
            ativo=True,
            email_verificado=True,
        )
        db.session.add(usuario)
        db.session.commit()
        flash(f"Usuário {usuario.nome_completo} criado.", "ok")
        return redirect(url_for("admin.usuarios_lista"))

    return render_template("admin/usuario_form.html", roles=roles, instituicoes=instituicoes, usuario=None)


@admin_bp.route("/usuarios/<int:usuario_id>/editar", methods=["GET", "POST"])
@admin_required
def usuario_editar(usuario_id):
    usuario = Usuario.query.get_or_404(usuario_id)
    roles = Role.query.all()
    instituicoes = Instituicao.query.filter_by(ativa=True).order_by(Instituicao.nome).all()

    if request.method == "POST":
        usuario.nome_completo = request.form["nome_completo"].strip()
        usuario.role_id = int(request.form["role_id"])
        usuario.ativo = "ativo" in request.form

        inst_id = request.form.get("instituicao_id") or None
        usuario.instituicao_id = int(inst_id) if inst_id else None

        nova_senha = request.form.get("senha", "").strip()
        if nova_senha:
            if len(nova_senha) < 6:
                flash("A senha deve ter pelo menos 6 caracteres.", "erro")
                return render_template("admin/usuario_form.html", roles=roles, instituicoes=instituicoes, usuario=usuario)
            usuario.senha_hash = bcrypt.generate_password_hash(nova_senha).decode("utf-8")

        db.session.commit()
        flash("Usuário atualizado.", "ok")
        return redirect(url_for("admin.usuarios_lista"))

    return render_template("admin/usuario_form.html", roles=roles, instituicoes=instituicoes, usuario=usuario)


@admin_bp.route("/usuarios/<int:usuario_id>/desativar", methods=["POST"])
@admin_required
def usuario_desativar(usuario_id):
    usuario = Usuario.query.get_or_404(usuario_id)
    usuario.ativo = False
    db.session.commit()
    flash(f"Usuário {usuario.nome_completo} desativado.", "ok")
    return redirect(url_for("admin.usuarios_lista"))


# ---------------------------------------------------------------------------
# Instituições (apenas admin_master)
# ---------------------------------------------------------------------------
@admin_bp.route("/instituicoes")
@admin_master_required
def instituicoes_lista():
    instituicoes = Instituicao.query.order_by(Instituicao.nome).all()
    return render_template("admin/instituicoes_lista.html", instituicoes=instituicoes)


@admin_bp.route("/instituicoes/nova", methods=["GET", "POST"])
@admin_master_required
def instituicao_nova():
    if request.method == "POST":
        inst = Instituicao(
            nome=request.form["nome"].strip(),
            cidade=request.form.get("cidade", "").strip() or None,
            ativa=True,
        )
        db.session.add(inst)
        db.session.commit()
        flash(f"Instituição '{inst.nome}' criada.", "ok")
        return redirect(url_for("admin.instituicoes_lista"))
    return render_template("admin/instituicao_form.html", instituicao=None)


@admin_bp.route("/instituicoes/<int:inst_id>/editar", methods=["GET", "POST"])
@admin_master_required
def instituicao_editar(inst_id):
    inst = Instituicao.query.get_or_404(inst_id)
    if request.method == "POST":
        inst.nome = request.form["nome"].strip()
        inst.cidade = request.form.get("cidade", "").strip() or None
        inst.ativa = "ativa" in request.form
        db.session.commit()
        flash("Instituição atualizada.", "ok")
        return redirect(url_for("admin.instituicoes_lista"))
    return render_template("admin/instituicao_form.html", instituicao=inst)
