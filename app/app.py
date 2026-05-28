# app.py
import os
from flask import Flask, request, jsonify
from app.controllers.db import db, Paciente, calcular_score_paciente

app = Flask(__name__)

# 1. Configure the Database URL from Docker's environment variables
# If it can't find the Docker variable, it defaults to a local test string
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
    'DATABASE_URL', 
    'postgresql://buko_admin:buko_password@localhost:5432/sxf_checklist'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 2. Bind the database to the Flask app
db.init_app(app)

# 3. Create the API Route to register a patient
@app.route('/api/pacientes', methods=['POST'])
def criar_paciente():
    # Grab the JSON data sent by Postman
    dados = request.get_json()

    # Validate that we got data
    if not dados:
        return jsonify({"erro": "Nenhum dado fornecido"}), 400

    try:
        # Create a new Paciente object using the data
        novo_paciente = Paciente(
            nome_completo=dados['nome_completo'],
            data_nascimento=dados['data_nascimento'],
            genero=dados['genero'],
            cpf=dados.get('cpf') # .get() allows it to be empty/null
        )

        # Add to database and save (commit)
        db.session.add(novo_paciente)
        db.session.commit()

        # Return a success message!
        return jsonify({
            "mensagem": "Paciente cadastrado com sucesso!",
            "paciente": novo_paciente.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"erro": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
