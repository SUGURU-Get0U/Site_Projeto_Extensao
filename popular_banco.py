"""
Popula o banco sxf_local.db com dados fictícios para demonstração:
instituições, profissionais, pacientes e avaliações (relatórios).

Uso:
    python popular_banco.py

A chave de criptografia é derivada de uma frase fixa, então é reprodutível.
Rode o app com a MESMA chave (use o iniciar.ps1) para os campos criptografados
(CPF, telefone, e-mail) aparecerem corretos.
"""
import base64
import hashlib
import os
import random
from datetime import datetime, timedelta, date

# --- Chave de criptografia FIXA (precisa ser a mesma usada para rodar o app) ---
CHAVE = base64.urlsafe_b64encode(hashlib.sha256(b"sxf-chave-fixa-2026").digest()).decode()
os.environ.setdefault("ENCRYPTION_KEY", CHAVE)
os.environ.setdefault("FLASK_SECRET_KEY", "sxf-secret-fixo-2026")

from app.app import app, db, bcrypt  # noqa: E402
from app.models import (  # noqa: E402
    Instituicao, Usuario, Paciente, Avaliacao, AvaliacaoSintoma, Sintoma, Role,
)
from app.calculo_back_end import calcular_score, SINTOMAS, LIMIAR  # noqa: E402

random.seed(2026)  # reprodutível

NOMES = [
    "Lucas Almeida", "Sofia Carvalho", "Miguel Santos", "Helena Oliveira",
    "Davi Pereira", "Alice Rodrigues", "Theo Fernandes", "Laura Gomes",
    "Pedro Henrique Lima", "Manuela Costa", "Gabriel Souza", "Valentina Ribeiro",
    "Bernardo Martins", "Cecília Araújo", "Heitor Barbosa", "Maria Luiza Rocha",
    "Arthur Cardoso", "Isabella Nunes", "Benjamin Teixeira", "Lívia Monteiro",
]
RESPONSAVEIS = [
    "Ana Paula", "Carlos Eduardo", "Fernanda Lima", "Roberto Dias",
    "Juliana Mendes", "Marcos Vinícius", "Patrícia Gomes", "Rafael Souza",
]
OBS_PACIENTE = [
    "Acompanhamento neuropediátrico em andamento.",
    "Histórico familiar relevante para investigação.",
    "Encaminhado pela escola para avaliação.",
    "Primeira consulta no serviço.",
    "Retorno para reavaliação semestral.",
    "",
]
OBS_AVAL = [
    "Avaliação de triagem inicial.",
    "Reavaliação após acompanhamento.",
    "Checklist aplicado pela equipe multidisciplinar.",
    "Resultado discutido com a família.",
    "",
]


def gera_cpf():
    return "".join(str(random.randint(0, 9)) for _ in range(11))


def gera_telefone():
    return f"(41) 9{random.randint(1000,9999)}-{random.randint(1000,9999)}"


def main():
    with app.app_context():
        # ------------------------------------------------------------------
        # Garante schema e dados base (roles, sintomas, admin)
        # ------------------------------------------------------------------
        db.create_all()

        # ---- Instituições ----
        instituicoes_def = [
            {"id": 1, "nome": "Hospital Infantil Pequeno Príncipe", "cidade": "Curitiba",
             "estado": "PR", "cnpj": "12.345.678/0001-90", "telefone": "(41) 3310-1010",
             "email": "contato@pequenoprincipe.org.br"},
            {"id": 2, "nome": "Instituto Buko Kaesemodel", "cidade": "Curitiba",
             "estado": "PR", "cnpj": "98.765.432/0001-21", "telefone": "(41) 3220-2020",
             "email": "ibk@ibk.org.br"},
            {"id": 3, "nome": "Clínica NeuroVida", "cidade": "São José dos Pinhais",
             "estado": "PR", "cnpj": "11.222.333/0001-44", "telefone": "(41) 3033-3030",
             "email": "atendimento@neurovida.com.br"},
        ]
        for d in instituicoes_def:
            inst = Instituicao.query.get(d["id"])
            if inst is None:
                inst = Instituicao(id=d["id"])
                db.session.add(inst)
            inst.nome = d["nome"]
            inst.cidade = d["cidade"]
            inst.estado = d["estado"]
            inst.cnpj = d["cnpj"]
            inst.telefone = d["telefone"]
            inst.email = d["email"]
            inst.ativa = True
        db.session.commit()

        # ---- Profissionais ----
        profissionais_def = [
            {"nome": "Dra. Mariana Lopes", "email": "mariana@sxf.com", "inst": 1, "role": Role.ADMIN},
            {"nome": "Dr. Felipe Andrade", "email": "felipe@sxf.com", "inst": 1, "role": Role.PROFISSIONAL},
            {"nome": "Dra. Carolina Reis", "email": "carolina@sxf.com", "inst": 2, "role": Role.PROFISSIONAL},
            {"nome": "Dr. João Vitor Mello", "email": "joaovitor@sxf.com", "inst": 3, "role": Role.PROFISSIONAL},
        ]
        prof_ids = []
        for d in profissionais_def:
            u = Usuario.query.filter_by(email=d["email"]).first()
            if u is None:
                u = Usuario(email=d["email"])
                db.session.add(u)
            u.nome_completo = d["nome"]
            u.role_id = d["role"]
            u.instituicao_id = d["inst"]
            u.senha_hash = bcrypt.generate_password_hash("Senha@2026").decode("utf-8")
            u.ativo = True
            u.email_verificado = True
            db.session.flush()
            prof_ids.append((u.id, d["inst"]))
        db.session.commit()

        # ---- Pacientes ----
        if Paciente.query.count() > 0:
            print(f"Já existem {Paciente.query.count()} pacientes. Pulando criação de pacientes.")
            pacientes = Paciente.query.all()
        else:
            pacientes = []
            hoje = date.today()
            for i, nome in enumerate(NOMES):
                genero = random.choice(["M", "M", "M", "F"])  # SXF mais comum em meninos
                idade_anos = random.randint(3, 16)
                nasc = date(hoje.year - idade_anos, random.randint(1, 12), random.randint(1, 28))
                prof_id, inst_id = random.choice(prof_ids)
                p = Paciente(
                    instituicao_id=inst_id,
                    nome_completo=nome,
                    data_nascimento=nasc,
                    genero=genero,
                    cpf=gera_cpf(),
                    nome_responsavel=random.choice(RESPONSAVEIS),
                    telefone_responsavel=gera_telefone(),
                    email_responsavel=f"{nome.split()[0].lower()}.resp@email.com",
                    observacoes=random.choice(OBS_PACIENTE),
                    cadastrado_por=prof_id,
                    ativo=True,
                    criado_em=datetime.utcnow() - timedelta(days=random.randint(10, 300)),
                )
                db.session.add(p)
                db.session.flush()
                pacientes.append(p)
            db.session.commit()
            print(f"Criados {len(pacientes)} pacientes.")

        # ---- Avaliações ----
        if Avaliacao.query.count() > 0:
            print(f"Já existem {Avaliacao.query.count()} avaliações. Pulando criação de avaliações.")
        else:
            total_aval = 0
            for p in pacientes:
                genero_calc = "homem" if p.genero == "M" else "mulher"
                qtd = random.randint(1, 3)
                for _ in range(qtd):
                    # escolhe aleatoriamente sintomas presentes
                    aplicaveis = [sid for sid, s in SINTOMAS.items() if s[genero_calc] is not None]
                    n_marcados = random.randint(0, len(aplicaveis))
                    marcados = set(random.sample(aplicaveis, n_marcados))
                    resultado = calcular_score(genero_calc, marcados)

                    prof_id = p.cadastrado_por
                    dias_atras = random.randint(1, 240)
                    realizada = datetime.utcnow() - timedelta(days=dias_atras, hours=random.randint(0, 23))

                    av = Avaliacao(
                        paciente_id=p.id,
                        usuario_id=prof_id,
                        instituicao_id=p.instituicao_id,
                        score=resultado["score"],
                        limiar_aplicado=resultado["limiar"],
                        recomenda_teste=resultado["encaminhar"],
                        status="finalizada",
                        observacoes=random.choice(OBS_AVAL),
                        realizada_em=realizada,
                        finalizada_em=realizada + timedelta(minutes=random.randint(5, 40)),
                        criado_em=realizada,
                    )
                    db.session.add(av)
                    db.session.flush()

                    # sintomas da avaliação
                    for sid in aplicaveis:
                        presente = sid in marcados
                        peso = SINTOMAS[sid][genero_calc]
                        db.session.add(AvaliacaoSintoma(
                            avaliacao_id=av.id,
                            sintoma_id=sid,
                            presente=presente,
                            contribuicao=peso if presente else 0,
                        ))
                    total_aval += 1
            db.session.commit()
            print(f"Criadas {total_aval} avaliações.")

        # ------------------------------------------------------------------
        # Resumo
        # ------------------------------------------------------------------
        print("\n========= RESUMO DO BANCO =========")
        print(f"Instituições : {Instituicao.query.count()}")
        print(f"Usuários     : {Usuario.query.count()}")
        print(f"Pacientes    : {Paciente.query.count()}")
        print(f"Avaliações   : {Avaliacao.query.count()}")
        rec = Avaliacao.query.filter_by(recomenda_teste=True).count()
        print(f"  > recomendam teste: {rec}")
        print("===================================")
        print(f"\nCHAVE DE CRIPTOGRAFIA usada (ENCRYPTION_KEY):\n{CHAVE}")


if __name__ == "__main__":
    main()
