import os
import click
from flask.cli import with_appcontext
from app.app import app, _bootstrap_db, db


@app.cli.command("init-db")
@with_appcontext
def init_db():
    """Inicializa o banco de dados com dados padrão."""
    click.echo("Inicializando banco de dados...")
    _bootstrap_db()
    click.echo("Banco de dados inicializado com sucesso!")


if __name__ == "__main__":
    app.cli()
