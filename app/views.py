from app.app import app
from flask import render_template


@app.route('/')
def cadastro():
    return render_template("cadastro/cadastro.html")