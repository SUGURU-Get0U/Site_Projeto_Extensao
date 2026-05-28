import os

from flask import Flask
from flask_bcrypt import Bcrypt
from flask_login import LoginManager
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("FLASK_SECRET_KEY", "dev-secret-change-me")
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get(
    "DATABASE_URL",
    "sqlite:///" + os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sxf_local.db"),
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

login_manager = LoginManager(app)
login_manager.login_view = "auth.login"
login_manager.login_message = "Faça login para acessar esta página."
login_manager.login_message_category = "aviso"


@login_manager.user_loader
def load_user(user_id):
    from app.models import Usuario
    return Usuario.query.get(int(user_id))


def _bootstrap_db():
    from app import models
    from app.calculo_back_end import SINTOMAS as SINTOMAS_PY
    from app.models import Role, Sintoma, Usuario

    db.create_all()

    if Role.query.count() == 0:
        db.session.add_all([
            Role(id=1, nome="admin_master", descricao="Administrador com acesso total"),
            Role(id=2, nome="admin", descricao="Administrador institucional"),
            Role(id=3, nome="profissional", descricao="Profissional de saúde"),
        ])
        db.session.commit()

    if Usuario.query.count() == 0:
        admin = Usuario(
            role_id=1,
            nome_completo="Administrador Master",
            email="admin@sxf.com",
            senha_hash=bcrypt.generate_password_hash("Admin@2026").decode("utf-8"),
            ativo=True,
            email_verificado=True,
        )
        db.session.add(admin)
        db.session.commit()

    if Sintoma.query.count() == 0:
        for id_, dados in SINTOMAS_PY.items():
            db.session.add(Sintoma(
                id=id_,
                codigo=f"SXF_{id_:03d}",
                nome=dados["nome"],
                peso_masculino=dados["homem"] or 0,
                peso_feminino=dados["mulher"] or 0,
                ativo=True,
                ordem=id_,
            ))
        db.session.commit()


from app import views  # noqa: E402,F401
from app.auth import auth_bp  # noqa: E402
from app.admin import admin_bp  # noqa: E402
from app.relatorios import relatorios_bp  # noqa: E402

app.register_blueprint(auth_bp)
app.register_blueprint(admin_bp)
app.register_blueprint(relatorios_bp)

with app.app_context():
    _bootstrap_db()

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
