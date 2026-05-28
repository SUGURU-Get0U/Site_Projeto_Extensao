import csv
import io
from datetime import datetime

from flask import Blueprint, Response, render_template, request
from flask_login import current_user, login_required
from sqlalchemy import and_

from app.app import db
from app.models import Avaliacao, Paciente, Usuario

relatorios_bp = Blueprint("relatorios", __name__, url_prefix="/relatorios")


def _query_filtrada():
    q = (
        db.session.query(Avaliacao)
        .join(Paciente, Avaliacao.paciente_id == Paciente.id)
        .filter(Paciente.ativo == True)
    )

    # profissional só vê as próprias avaliações
    if not current_user.is_admin:
        q = q.filter(Avaliacao.usuario_id == current_user.id)

    filtros = []

    data_ini = request.args.get("data_ini")
    data_fim = request.args.get("data_fim")
    if data_ini:
        try:
            filtros.append(Avaliacao.realizada_em >= datetime.strptime(data_ini, "%Y-%m-%d"))
        except ValueError:
            pass
    if data_fim:
        try:
            filtros.append(Avaliacao.realizada_em <= datetime.strptime(data_fim + " 23:59:59", "%Y-%m-%d %H:%M:%S"))
        except ValueError:
            pass

    genero = request.args.get("genero")
    if genero in ("M", "F"):
        filtros.append(Paciente.genero == genero)

    recomenda = request.args.get("recomenda")
    if recomenda == "sim":
        filtros.append(Avaliacao.recomenda_teste == True)
    elif recomenda == "nao":
        filtros.append(Avaliacao.recomenda_teste == False)

    status = request.args.get("status")
    if status in ("finalizada", "rascunho", "cancelada", "revisada"):
        filtros.append(Avaliacao.status == status)

    if filtros:
        q = q.filter(and_(*filtros))

    return q.order_by(Avaliacao.realizada_em.desc())


@relatorios_bp.route("/")
@login_required
def lista():
    query = _query_filtrada()

    # paginação simples
    pagina = int(request.args.get("pagina", 1))
    por_pagina = 20
    total = query.count()
    avaliacoes = query.offset((pagina - 1) * por_pagina).limit(por_pagina).all()
    total_paginas = max(1, (total + por_pagina - 1) // por_pagina)

    usuarios = Usuario.query.filter_by(ativo=True).order_by(Usuario.nome_completo).all() if current_user.is_admin else []

    return render_template(
        "relatorios/lista.html",
        avaliacoes=avaliacoes,
        pagina=pagina,
        total_paginas=total_paginas,
        total=total,
        usuarios=usuarios,
    )


@relatorios_bp.route("/exportar-csv")
@login_required
def exportar_csv():
    query = _query_filtrada()
    avaliacoes = query.all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "ID", "Data", "Paciente", "Sexo", "Idade", "Score",
        "Limiar", "Recomenda Teste", "Status", "Realizado por",
    ])
    for a in avaliacoes:
        writer.writerow([
            a.id,
            a.realizada_em.strftime("%d/%m/%Y %H:%M"),
            a.paciente.nome_completo,
            a.paciente.genero_extenso,
            a.paciente.idade,
            float(a.score),
            float(a.limiar_aplicado),
            "Sim" if a.recomenda_teste else "Não",
            a.status,
            a.usuario.nome_completo if a.usuario else "",
        ])

    output.seek(0)
    return Response(
        "﻿" + output.read(),  # BOM para Excel abrir UTF-8 corretamente
        mimetype="text/csv; charset=utf-8",
        headers={"Content-Disposition": "attachment; filename=relatorio_sxf.csv"},
    )
