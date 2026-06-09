import os
from flask import Flask, request, jsonify, render_template  # Added render_template
from app.controllers.db import db, Paciente, calcular_score_paciente

app = Flask(__name__)

# 1. Configure the Database URL from Docker's environment variables
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL', 
    'postgresql://buko_admin:buko_password@localhost:5432/sxf_checklist'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 2. Bind the database to the Flask app
db.init_app(app)

# =====================================================================
# HTML PAGE ROUTES (Moved from views.py to prevent circular imports)
# =====================================================================

@app.route('/')
def cadastro():
    return render_template("cadastro/cadastro.html")

@app.route('/index')
def index():
    return render_template("index/index.html")

@app.route('/login')
def login():
    return render_template("login/login.html")

@app.route('/sobre-nos')
def sobre_nos():
    return render_template("Abas_Extras/Sobre_nós.html")

@app.route('/saiba-mais')
def saiba_mais():
    return render_template("Abas_Extras/Saiba_mais.html")

@app.route('/login2')
def login2():
    return render_template("login/login2.html")

# =====================================================================
# API ROUTES
# =====================================================================

@app.route('/api/pacientes', methods=['POST'])
def criar_paciente():
    dados = request.get_json()


    if not dados:
        return jsonify({"erro": "Nenhum dado fornecido"}), 400

    try:

<<<<<<< HEAD
def _bootstrap_db():
    from app import models
    from app.calculo_back_end import SINTOMAS as SINTOMAS_PY
    from app.models import Instituicao, Paciente, Role, Sintoma, Usuario

    db.create_all()

    if Role.query.count() == 0:
        db.session.add_all([
            Role(id=1, nome="admin_master", descricao="Administrador com acesso total"),
            Role(id=2, nome="admin", descricao="Administrador institucional"),
            Role(id=3, nome="profissional", descricao="Profissional de saúde"),
            Role(id=4, nome="paciente", descricao="Paciente — acesso somente ao próprio histórico"),
        ])
        db.session.commit()

    if Instituicao.query.count() == 0:
        inst = Instituicao(id=1, nome="Hospital Padrão", cidade="—", ativa=True)
        db.session.add(inst)
        db.session.commit()

    if Usuario.query.count() == 0:
        admin = Usuario(
            role_id=1,
            instituicao_id=1,
            nome_completo="Administrador Master",
            email="admin@sxf.com",
            senha_hash=bcrypt.generate_password_hash("Admin@2026").decode("utf-8"),
            ativo=True,
            email_verificado=True,
=======
        id_usuario = dados.get('cadastrado_por', 1)
        
        novo_paciente = Paciente(
            nome_completo=dados['nome_completo'],
            data_nascimento=dados['data_nascimento'],
            genero=dados['genero'],
            cpf=dados.get('cpf'),
            cadastrado_por=int(id_usuario) 
>>>>>>> f8cb01aee8bd7e353eae1e09290b2a89a1fecc8e
        )

        db.session.add(novo_paciente)
        db.session.commit()

        return jsonify({
            "mensagem": "Paciente cadastrado com sucesso!",
            "paciente": novo_paciente.to_dict()
        }), 201

<<<<<<< HEAD
    pacientes_sem_hash = Paciente.query.filter(Paciente.cpf_hash.is_(None)).all()
    if pacientes_sem_hash:
        for paciente in pacientes_sem_hash:
            paciente.cpf_hash = Paciente.hash_cpf(paciente.cpf)
        db.session.commit()


from app import views  # noqa: E402,F401
from app import cli  # noqa: E402,F401
from app.auth import auth_bp  # noqa: E402
from app.admin import admin_bp  # noqa: E402
from app.relatorios import relatorios_bp  # noqa: E402

app.register_blueprint(auth_bp)
app.register_blueprint(admin_bp)
app.register_blueprint(relatorios_bp)
=======
    except Exception as e:
        db.session.rollback()
        return jsonify({"erro": str(e)}), 500
>>>>>>> f8cb01aee8bd7e353eae1e09290b2a89a1fecc8e

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")