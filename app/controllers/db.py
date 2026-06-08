# app/controllers/db.py
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Paciente(db.Model):
    __tablename__ = 'pacientes' 
    
    id = db.Column(db.Integer, primary_key=True)
    nome_completo = db.Column(db.String(150), nullable=False)
    data_nascimento = db.Column(db.Date, nullable=False)
    genero = db.Column(db.String(1), nullable=False)
    cpf = db.Column(db.Text) # Changed to Text to match your encrypted SQL schema
    
    cadastrado_por = db.Column(db.Integer, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "nome": self.nome_completo,
            "genero": self.genero
        }
        
# We wrap the execution in a function so it only runs when WE call it, not automatically.
def calcular_score_paciente(paciente_id):
    try:
        db.session.execute(db.text("CALL sp_calcular_score(:id)"), {"id": paciente_id})
        db.session.commit()
        return True
    except Exception as e:
        db.session.rollback()
        print(f"Erro ao calcular score: {e}")
        return False