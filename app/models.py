import os
import warnings
from datetime import datetime

from cryptography.fernet import Fernet, InvalidToken
from flask_login import UserMixin
from sqlalchemy.types import Text, TypeDecorator

from app.app import db


# ---------------------------------------------------------------------------
# Criptografia de campos sensíveis
# ---------------------------------------------------------------------------
_fernet_instance = None


def _get_fernet():
    global _fernet_instance
    if _fernet_instance is None:
        key = os.environ.get("ENCRYPTION_KEY")
        if not key:
            key = Fernet.generate_key().decode()
            warnings.warn(
                "ENCRYPTION_KEY não definida. Usando chave temporária — "
                "dados criptografados não sobrevivem a reinicializações em produção.",
                stacklevel=2,
            )
        _fernet_instance = Fernet(key.encode() if isinstance(key, str) else key)
    return _fernet_instance


class EncryptedString(TypeDecorator):
    """Armazena strings criptografadas com Fernet (AES-128-CBC + HMAC-SHA256)."""
    impl = Text
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return _get_fernet().encrypt(value.encode()).decode()

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        try:
            return _get_fernet().decrypt(value.encode()).decode()
        except (InvalidToken, Exception):
            return value  # Retorna como está se não estiver criptografado (migração)


# ---------------------------------------------------------------------------
# Instituição (Hospital / Clínica)
# ---------------------------------------------------------------------------
class Instituicao(db.Model):
    __tablename__ = "instituicoes"
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(200), nullable=False)
    cidade = db.Column(db.String(100))
    ativa = db.Column(db.Boolean, nullable=False, default=True)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Instituicao {self.nome}>"


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
    PACIENTE = 4


class Usuario(UserMixin, db.Model):
    __tablename__ = "usuarios"
    id = db.Column(db.Integer, primary_key=True)
    role_id = db.Column(db.Integer, db.ForeignKey("roles.id"), nullable=False, default=Role.PROFISSIONAL)
    instituicao_id = db.Column(db.Integer, db.ForeignKey("instituicoes.id"), nullable=True)
    nome_completo = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), nullable=False, unique=True)
    senha_hash = db.Column(db.String(255), nullable=False)
    ativo = db.Column(db.Boolean, nullable=False, default=True)
    email_verificado = db.Column(db.Boolean, nullable=False, default=False)
    ultimo_login = db.Column(db.DateTime)
    tentativas_login = db.Column(db.Integer, nullable=False, default=0)
    bloqueado_ate = db.Column(db.DateTime)
    # Vínculo opcional com registro de paciente (usado quando role = PACIENTE)
    paciente_id = db.Column(db.Integer, db.ForeignKey("pacientes.id"), nullable=True)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)
    atualizado_em = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    role = db.relationship("Role", lazy="joined")
    instituicao = db.relationship("Instituicao", foreign_keys=[instituicao_id], lazy="joined")
    paciente_vinculo = db.relationship("Paciente", foreign_keys=[paciente_id], lazy="joined")

    @property
    def is_admin(self):
        return self.role_id in (Role.ADMIN_MASTER, Role.ADMIN)

    @property
    def is_admin_master(self):
        return self.role_id == Role.ADMIN_MASTER

    @property
    def is_profissional(self):
        return self.role_id in (Role.ADMIN_MASTER, Role.ADMIN, Role.PROFISSIONAL)

    @property
    def is_paciente(self):
        return self.role_id == Role.PACIENTE

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
    instituicao_id = db.Column(db.Integer, db.ForeignKey("instituicoes.id"), nullable=True)
    nome_completo = db.Column(db.String(150), nullable=False)
    data_nascimento = db.Column(db.Date, nullable=False)
    genero = db.Column(db.String(1), nullable=False)
    cpf = db.Column(EncryptedString)                         # criptografado
    nome_responsavel = db.Column(db.String(150))
    telefone_responsavel = db.Column(EncryptedString)        # criptografado
    email_responsavel = db.Column(EncryptedString)           # criptografado
    observacoes = db.Column(db.Text)
    cadastrado_por = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    ativo = db.Column(db.Boolean, nullable=False, default=True)
    criado_em = db.Column(db.DateTime, default=datetime.utcnow)
    atualizado_em = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    cadastrador = db.relationship("Usuario", foreign_keys=[cadastrado_por], lazy="joined")
    instituicao = db.relationship("Instituicao", foreign_keys=[instituicao_id], lazy="joined")
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
