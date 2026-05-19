from app.app import app
from flask import render_template


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