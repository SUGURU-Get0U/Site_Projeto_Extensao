"""Checklist de triagem da Síndrome do X Frágil.

Pesos e limiares derivados do Random Forest do artigo de Herai/Romero
(coorte IBK 2018-2023, 419 indivíduos com mutação completa).
Score = Σ(Peso_j × X_ij), com X_ij ∈ {0, 1}.
"""

SINTOMAS = {
    1:  {"nome": "Deficiência intelectual",       "homem": 0.32, "mulher": 0.20},
    2:  {"nome": "Face alongada/orelhas",         "homem": 0.29, "mulher": 0.09},
    3:  {"nome": "Macroorquidismo",               "homem": 0.26, "mulher": None},
    4:  {"nome": "Hipermobilidade articular",     "homem": 0.19, "mulher": 0.04},
    5:  {"nome": "Dificuldades de aprendizagem",  "homem": 0.18, "mulher": 0.28},
    6:  {"nome": "Déficit de atenção",            "homem": 0.17, "mulher": 0.12},
    7:  {"nome": "Movimentos repetitivos",        "homem": 0.17, "mulher": 0.05},
    8:  {"nome": "Atraso na fala",                "homem": 0.14, "mulher": 0.01},
    9:  {"nome": "Hiperatividade",                "homem": 0.12, "mulher": 0.04},
    10: {"nome": "Evita contato visual",          "homem": 0.06, "mulher": 0.08},
    11: {"nome": "Evita contato físico",          "homem": 0.04, "mulher": 0.07},
    12: {"nome": "Agressividade",                 "homem": 0.01, "mulher": 0.02},
}

LIMIAR = {"homem": 0.56, "mulher": 0.55}


def sintomas_para_genero(genero: str):
    """Devolve os sintomas aplicáveis ao gênero (omite peso None)."""
    if genero not in ("homem", "mulher"):
        raise ValueError("genero deve ser 'homem' ou 'mulher'")
    return {
        id_: {"nome": s["nome"], "peso": s[genero]}
        for id_, s in SINTOMAS.items()
        if s[genero] is not None
    }


def calcular_score(genero: str, sintomas_marcados):
    """Calcula o score e a recomendação de encaminhamento.

    Args:
        genero: "homem" ou "mulher".
        sintomas_marcados: iterável com os IDs dos sintomas presentes.

    Returns:
        dict com score, limiar, encaminhar (bool) e detalhamento.
    """
    if genero not in ("homem", "mulher"):
        raise ValueError("genero deve ser 'homem' ou 'mulher'")

    marcados = {int(i) for i in sintomas_marcados}
    detalhes = []
    score = 0.0

    for id_, dados in SINTOMAS.items():
        peso = dados[genero]
        presente = id_ in marcados and peso is not None
        if presente:
            score += peso
        detalhes.append({
            "id": id_,
            "nome": dados["nome"],
            "peso": peso,
            "presente": presente,
        })

    limiar = LIMIAR[genero]
    return {
        "score": round(score, 2),
        "limiar": limiar,
        "encaminhar": score >= limiar,
        "genero": genero,
        "detalhes": detalhes,
    }