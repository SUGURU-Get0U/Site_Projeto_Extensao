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

        id_usuario = dados.get('cadastrado_por', 1)
        
        novo_paciente = Paciente(
            nome_completo=dados['nome_completo'],
            data_nascimento=dados['data_nascimento'],
            genero=dados['genero'],
            cpf=dados.get('cpf'),
            cadastrado_por=int(id_usuario) 
        )

        db.session.add(novo_paciente)
        db.session.commit()

        return jsonify({
            "mensagem": "Paciente cadastrado com sucesso!",
            "paciente": novo_paciente.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"erro": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")