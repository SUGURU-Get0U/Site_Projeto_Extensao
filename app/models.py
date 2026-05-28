from datetime import datetime

from flask_login import UserMixin

from app.app import db


# ---------------------------------------------------------------------------
# Controle de Acesso
# ---------------------------------------------------------------------------
class Role(db.Model):
    __tablename__ = "roles"
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(50), nullable=False, unique=True)
    descricao = db.Column(db.String(255), nullable=False, default="")
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)

    ADMIN_MASTER = 1
    ADMIN = 2
    PROFISSIONAL = 3


class Usuario(UserMixin, db.Model):
    __tablename__ = "usuarios"
    id = db.Column(db.Integer, primary_key=True)
    role_id = db.Column(db.Integer, db.ForeignKey("roles.id"), nullable=False, default=3)
    nome_completo = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), nullable=False, unique=True)
    senha_hash = db.Column(db.String(255), nullable=False)
    ativo = db.Column(db.Boolean, nullable=False, default=True)
    email_verificado = db.Column(db.Boolean, nullable=False, default=False)
    ultimo_login = db.Column(db.DateTime)
    tentativas_login = db.Column(db.Integer, nullable=False, default=0)
    bloqueado_ate = db.Column(db.DateTime)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)
    atualizado_em = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    role = db.relationship("Role", lazy="joined")

    @property
    def is_admin(self):
        return self.role_id in (Role.ADMIN_MASTER, Role.ADMIN)

    @property
    def is_admin_master(self):
        return self.role_id == Role.ADMIN_MASTER

    def esta_bloqueado(self):
        if self.bloqueado_ate and self.bloqueado_ate > datetime.utcnow():
            return True
        return False

    def __repr__(self):
        return f"<Usuario {self.email}>"


# ---------------------------------------------------------------------------
# Pacientes
# ---------------------------------------------------------------------------
class Paciente(db.Model):
    __tablename__ = "pacientes"
    id = db.Column(db.Integer, primary_key=True)
    nome_completo = db.Column(db.String(150), nullable=False)
    data_nascimento = db.Column(db.Date, nullable=False)
    genero = db.Column(db.String(1), nullable=False)
    cpf = db.Column(db.String(14), unique=True)
    nome_responsavel = db.Column(db.String(150))
    telefone_responsavel = db.Column(db.String(20))
    email_responsavel = db.Column(db.String(150))
    observacoes = db.Column(db.Text)
    cadastrado_por = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    ativo = db.Column(db.Boolean, nullable=False, default=True)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)
    atualizado_em = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    cadastrador = db.relationship("Usuario", lazy="joined")
    avaliacoes = db.relationship(
        "Avaliacao", backref="paciente", lazy=True,
        order_by="Avaliacao.realizada_em.desc()"
    )

    @property
    def idade(self):
        if not self.data_nascimento:
            return None
        hoje = datetime.utcnow().date()
        anos = hoje.year - self.data_nascimento.year
        if (hoje.month, hoje.day) < (self.data_nascimento.month, self.data_nascimento.day):
            anos -= 1
        return anos

    @property
    def genero_extenso(self):
        return "Masculino" if self.genero == "M" else "Feminino"


# ---------------------------------------------------------------------------
# Sintomas (catálogo)
# ---------------------------------------------------------------------------
class Sintoma(db.Model):
    __tablename__ = "sintomas"
    id = db.Column(db.Integer, primary_key=True)
    codigo = db.Column(db.String(20), nullable=False, unique=True)
    nome = db.Column(db.String(120), nullable=False)
    descricao = db.Column(db.Text)
    peso_masculino = db.Column(db.Numeric(5, 4), nullable=False, default=0)
    peso_feminino = db.Column(db.Numeric(5, 4), nullable=False, default=0)
    ativo = db.Column(db.Boolean, nullable=False, default=True)
    ordem = db.Column(db.Integer, nullable=False, default=0)

    def peso_para(self, genero):
        return float(self.peso_masculino if genero == "M" else self.peso_feminino)


# ---------------------------------------------------------------------------
# Avaliações
# ---------------------------------------------------------------------------
class Avaliacao(db.Model):
    __tablename__ = "avaliacoes"
    id = db.Column(db.Integer, primary_key=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey("pacientes.id"), nullable=False)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"))
    score = db.Column(db.Numeric(6, 4), nullable=False, default=0)
    limiar_aplicado = db.Column(db.Numeric(5, 4), nullable=False)
    recomenda_teste = db.Column(db.Boolean, nullable=False, default=False)
    status = db.Column(db.String(20), nullable=False, default="finalizada")
    observacoes = db.Column(db.Text)
    realizada_em = db.Column(db.DateTime, default=datetime.utcnow)
    finalizada_em = db.Column(db.DateTime)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)
    atualizado_em = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    usuario = db.relationship("Usuario", lazy="joined")
    sintomas = db.relationship(
        "AvaliacaoSintoma", backref="avaliacao", lazy=True,
        cascade="all, delete-orphan",
        order_by="AvaliacaoSintoma.sintoma_id"
    )


class AvaliacaoSintoma(db.Model):
    __tablename__ = "avaliacao_sintomas"
    avaliacao_id = db.Column(db.Integer, db.ForeignKey("avaliacoes.id"), primary_key=True)
    sintoma_id = db.Column(db.Integer, db.ForeignKey("sintomas.id"), primary_key=True)
    presente = db.Column(db.Boolean, nullable=False, default=False)
    contribuicao = db.Column(db.Numeric(5, 4), nullable=False, default=0)

    sintoma = db.relationship("Sintoma", lazy="joined")
