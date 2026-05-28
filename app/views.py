from datetime import datetime

from flask import flash, redirect, render_template, request, url_for
from flask_login import current_user, login_required

from app.app import app, db
from app.auth import admin_required
from app.calculo_back_end import LIMIAR
from app.models import Avaliacao, AvaliacaoSintoma, Paciente, Sintoma


# ---------------------------------------------------------------------------
# Páginas públicas / estáticas
# ---------------------------------------------------------------------------
@app.route("/")
def index_redirect():
    return redirect(url_for("index"))


@app.route("/index")
def index():
    return render_template("index/index.html")


@app.route("/sobre-nos")
def sobre_nos():
    return render_template("Abas_Extras/Sobre_nós.html")


@app.route("/saiba-mais")
def saiba_mais():
    return render_template("Abas_Extras/Saiba_mais.html")


@app.route("/cadastro")
def cadastro():
    return render_template("cadastro/cadastro.html")


@app.route("/interno")
@login_required
def interno():
    return render_template("Abas_Internas/menu_interno.html")


# ---------------------------------------------------------------------------
# Pacientes
# ---------------------------------------------------------------------------
@app.route("/pacientes")
@login_required
def pacientes_lista():
    busca = request.args.get("q", "").strip()
    genero = request.args.get("genero", "")
    q = Paciente.query.filter_by(ativo=True)

    if not current_user.is_admin:
        q = q.filter_by(cadastrado_por=current_user.id)

    if busca:
        q = q.filter(Paciente.nome_completo.ilike(f"%{busca}%"))
    if genero in ("M", "F"):
        q = q.filter_by(genero=genero)

    pacientes = q.order_by(Paciente.nome_completo).all()
    return render_template("pacientes/lista.html", pacientes=pacientes, busca=busca, genero=genero)


@app.route("/pacientes/novo", methods=["GET", "POST"])
@login_required
def pacientes_novo():
    if request.method == "POST":
        try:
            data_nasc = datetime.strptime(request.form["data_nascimento"], "%Y-%m-%d").date()
        except (KeyError, ValueError):
            flash("Data de nascimento inválida.", "erro")
            return render_template("pacientes/novo.html")

        paciente = Paciente(
            nome_completo=request.form["nome_completo"].strip(),
            data_nascimento=data_nasc,
            genero=request.form["genero"],
            cpf=request.form.get("cpf") or None,
            nome_responsavel=request.form.get("nome_responsavel") or None,
            telefone_responsavel=request.form.get("telefone_responsavel") or None,
            email_responsavel=request.form.get("email_responsavel") or None,
            observacoes=request.form.get("observacoes") or None,
            cadastrado_por=current_user.id,
        )
        db.session.add(paciente)
        db.session.commit()
        flash(f"Paciente {paciente.nome_completo} cadastrado.", "ok")
        return redirect(url_for("paciente_detalhe", paciente_id=paciente.id))

    return render_template("pacientes/novo.html")


@app.route("/pacientes/<int:paciente_id>")
@login_required
def paciente_detalhe(paciente_id):
    paciente = Paciente.query.get_or_404(paciente_id)
    return render_template("pacientes/detalhe.html", paciente=paciente)


@app.route("/pacientes/<int:paciente_id>/editar", methods=["GET", "POST"])
@login_required
def paciente_editar(paciente_id):
    paciente = Paciente.query.get_or_404(paciente_id)

    if not current_user.is_admin and paciente.cadastrado_por != current_user.id:
        flash("Sem permissão para editar este paciente.", "erro")
        return redirect(url_for("paciente_detalhe", paciente_id=paciente_id))

    if request.method == "POST":
        try:
            paciente.data_nascimento = datetime.strptime(request.form["data_nascimento"], "%Y-%m-%d").date()
        except (KeyError, ValueError):
            flash("Data inválida.", "erro")
            return render_template("pacientes/editar.html", paciente=paciente)

        paciente.nome_completo = request.form["nome_completo"].strip()
        paciente.genero = request.form["genero"]
        paciente.cpf = request.form.get("cpf") or None
        paciente.nome_responsavel = request.form.get("nome_responsavel") or None
        paciente.telefone_responsavel = request.form.get("telefone_responsavel") or None
        paciente.email_responsavel = request.form.get("email_responsavel") or None
        paciente.observacoes = request.form.get("observacoes") or None
        db.session.commit()
        flash("Paciente atualizado.", "ok")
        return redirect(url_for("paciente_detalhe", paciente_id=paciente.id))

    return render_template("pacientes/editar.html", paciente=paciente)


@app.route("/pacientes/<int:paciente_id>/desativar", methods=["POST"])
@admin_required
def paciente_desativar(paciente_id):
    paciente = Paciente.query.get_or_404(paciente_id)
    paciente.ativo = False
    db.session.commit()
    flash(f"Paciente {paciente.nome_completo} removido.", "ok")
    return redirect(url_for("pacientes_lista"))


# ---------------------------------------------------------------------------
# Avaliação
# ---------------------------------------------------------------------------
@app.route("/pacientes/<int:paciente_id>/avaliar", methods=["GET"])
@login_required
def avaliacao_form(paciente_id):
    paciente = Paciente.query.get_or_404(paciente_id)
    sintomas = Sintoma.query.filter_by(ativo=True).order_by(Sintoma.ordem).all()
    if paciente.genero == "F":
        sintomas = [s for s in sintomas if float(s.peso_feminino) > 0]
    return render_template("avaliacao/avaliacao.html", paciente=paciente, sintomas=sintomas)


@app.route("/pacientes/<int:paciente_id>/avaliar", methods=["POST"])
@login_required
def avaliacao_salvar(paciente_id):
    paciente = Paciente.query.get_or_404(paciente_id)
    marcados_ids = {int(i) for i in request.form.getlist("sintoma")}

    sintomas = Sintoma.query.filter_by(ativo=True).order_by(Sintoma.ordem).all()
    score = 0.0
    contribuicoes = []
    for s in sintomas:
        peso = s.peso_para(paciente.genero)
        presente = s.id in marcados_ids and peso > 0
        contrib = round(peso, 4) if presente else 0.0
        if presente:
            score += contrib
        contribuicoes.append((s.id, presente, contrib))

    limiar = LIMIAR["homem" if paciente.genero == "M" else "mulher"]
    score = round(score, 4)

    avaliacao = Avaliacao(
        paciente_id=paciente.id,
        usuario_id=current_user.id,
        score=score,
        limiar_aplicado=limiar,
        recomenda_teste=(score >= limiar),
        status="finalizada",
        observacoes=request.form.get("observacoes") or None,
        finalizada_em=datetime.utcnow(),
    )
    db.session.add(avaliacao)
    db.session.flush()

    for sintoma_id, presente, contrib in contribuicoes:
        db.session.add(AvaliacaoSintoma(
            avaliacao_id=avaliacao.id,
            sintoma_id=sintoma_id,
            presente=presente,
            contribuicao=contrib,
        ))
    db.session.commit()
    return redirect(url_for("avaliacao_resultado", avaliacao_id=avaliacao.id))


@app.route("/avaliacoes/<int:avaliacao_id>")
@login_required
def avaliacao_resultado(avaliacao_id):
    avaliacao = Avaliacao.query.get_or_404(avaliacao_id)
    return render_template("avaliacao/resultado.html", avaliacao=avaliacao)


@app.route("/avaliacoes/<int:avaliacao_id>/editar", methods=["GET", "POST"])
@login_required
def avaliacao_editar(avaliacao_id):
    avaliacao = Avaliacao.query.get_or_404(avaliacao_id)
    paciente = avaliacao.paciente

    if not current_user.is_admin and avaliacao.usuario_id != current_user.id:
        flash("Sem permissão para editar esta avaliação.", "erro")
        return redirect(url_for("avaliacao_resultado", avaliacao_id=avaliacao_id))

    sintomas = Sintoma.query.filter_by(ativo=True).order_by(Sintoma.ordem).all()
    if paciente.genero == "F":
        sintomas = [s for s in sintomas if float(s.peso_feminino) > 0]

    if request.method == "POST":
        marcados_ids = {int(i) for i in request.form.getlist("sintoma")}

        # Recalcula
        score = 0.0
        todos_sintomas = Sintoma.query.filter_by(ativo=True).order_by(Sintoma.ordem).all()
        for av_s in avaliacao.sintomas:
            s = next((x for x in todos_sintomas if x.id == av_s.sintoma_id), None)
            if not s:
                continue
            peso = s.peso_para(paciente.genero)
            presente = av_s.sintoma_id in marcados_ids and peso > 0
            contrib = round(peso, 4) if presente else 0.0
            av_s.presente = presente
            av_s.contribuicao = contrib
            if presente:
                score += contrib

        avaliacao.score = round(score, 4)
        avaliacao.recomenda_teste = (score >= float(avaliacao.limiar_aplicado))
        avaliacao.observacoes = request.form.get("observacoes") or None
        avaliacao.atualizado_em = datetime.utcnow()
        db.session.commit()
        flash("Avaliação atualizada.", "ok")
        return redirect(url_for("avaliacao_resultado", avaliacao_id=avaliacao.id))

    marcados_ids = {av_s.sintoma_id for av_s in avaliacao.sintomas if av_s.presente}
    return render_template(
        "avaliacao/editar.html",
        avaliacao=avaliacao,
        paciente=paciente,
        sintomas=sintomas,
        marcados_ids=marcados_ids,
    )


@app.route("/avaliacoes/<int:avaliacao_id>/cancelar", methods=["POST"])
@login_required
def avaliacao_cancelar(avaliacao_id):
    avaliacao = Avaliacao.query.get_or_404(avaliacao_id)

    if not current_user.is_admin and avaliacao.usuario_id != current_user.id:
        flash("Sem permissão.", "erro")
        return redirect(url_for("avaliacao_resultado", avaliacao_id=avaliacao_id))

    avaliacao.status = "cancelada"
    db.session.commit()
    flash("Avaliação cancelada.", "ok")
    return redirect(url_for("paciente_detalhe", paciente_id=avaliacao.paciente_id))


@app.route("/avaliacoes/<int:avaliacao_id>/imprimir")
@login_required
def avaliacao_imprimir(avaliacao_id):
    avaliacao = Avaliacao.query.get_or_404(avaliacao_id)
    return render_template("avaliacao/imprimir.html", avaliacao=avaliacao)


@app.route("/avaliacao")
@login_required
def avaliacao_index():
    return redirect(url_for("pacientes_lista"))
