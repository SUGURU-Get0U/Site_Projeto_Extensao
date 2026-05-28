from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.app import bcrypt, db
from app.auth import admin_required
from app.models import Role, Usuario

admin_bp = Blueprint("admin", __name__, url_prefix="/admin")


@admin_bp.route("/usuarios")
@admin_required
def usuarios_lista():
    usuarios = Usuario.query.order_by(Usuario.nome_completo).all()
    return render_template("admin/usuarios_lista.html", usuarios=usuarios)


@admin_bp.route("/usuarios/novo", methods=["GET", "POST"])
@admin_required
def usuario_novo():
    roles = Role.query.all()
    if request.method == "POST":
        email = request.form["email"].strip().lower()
        if Usuario.query.filter_by(email=email).first():
            flash("Este e-mail já está cadastrado.", "erro")
            return render_template("admin/usuario_form.html", roles=roles, usuario=None)

        senha = request.form["senha"]
        if len(senha) < 6:
            flash("A senha deve ter pelo menos 6 caracteres.", "erro")
            return render_template("admin/usuario_form.html", roles=roles, usuario=None)

        usuario = Usuario(
            role_id=int(request.form["role_id"]),
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

    return render_template("admin/usuario_form.html", roles=roles, usuario=None)


@admin_bp.route("/usuarios/<int:usuario_id>/editar", methods=["GET", "POST"])
@admin_required
def usuario_editar(usuario_id):
    usuario = Usuario.query.get_or_404(usuario_id)
    roles = Role.query.all()

    if request.method == "POST":
        usuario.nome_completo = request.form["nome_completo"].strip()
        usuario.role_id = int(request.form["role_id"])
        usuario.ativo = "ativo" in request.form

        nova_senha = request.form.get("senha", "").strip()
        if nova_senha:
            if len(nova_senha) < 6:
                flash("A senha deve ter pelo menos 6 caracteres.", "erro")
                return render_template("admin/usuario_form.html", roles=roles, usuario=usuario)
            usuario.senha_hash = bcrypt.generate_password_hash(nova_senha).decode("utf-8")

        db.session.commit()
        flash("Usuário atualizado.", "ok")
        return redirect(url_for("admin.usuarios_lista"))

    return render_template("admin/usuario_form.html", roles=roles, usuario=usuario)


@admin_bp.route("/usuarios/<int:usuario_id>/desativar", methods=["POST"])
@admin_required
def usuario_desativar(usuario_id):
    usuario = Usuario.query.get_or_404(usuario_id)
    usuario.ativo = False
    db.session.commit()
    flash(f"Usuário {usuario.nome_completo} desativado.", "ok")
    return redirect(url_for("admin.usuarios_lista"))
