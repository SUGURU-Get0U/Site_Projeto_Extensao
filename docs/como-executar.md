# 🐳 Como Executar o Projeto

[← Voltar ao README principal](../README.md)

---

## Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) e [Docker Compose](https://docs.docker.com/compose/)
- [Python 3.11+](https://www.python.org/) (apenas para desenvolvimento local sem Docker)
- [Poetry](https://python-poetry.org/docs/#installation) (apenas para desenvolvimento local)

---

## 🐳 Execução com Docker (Recomendado)

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/seu-projeto.git
cd seu-projeto

# 2. Configure as variáveis de ambiente
cp .env.example .env
# Edite o .env com seus valores

# 3. Suba o ambiente
docker compose up --build

# 4. Acesse no browser
# http://localhost:5000
```

Para rodar em background:
```bash
docker compose up --build -d
```

Para parar:
```bash
docker compose down
```

---

## 💻 Execução Local com Poetry

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/seu-projeto.git
cd seu-projeto

# 2. Instale as dependências
poetry install

# 3. Configure as variáveis de ambiente
cp .env.example .env

# 4. Ative o ambiente virtual
poetry shell

# 5. Execute a aplicação (modo desenvolvimento)
flask --app wsgi run --debug

# Acesse: http://localhost:5000
```

---

## 🧪 Rodando os Testes

```bash
# Com Poetry
poetry run pytest

# Com cobertura
poetry run pytest --cov=app --cov-report=term-missing

# Com Docker
docker compose run --rm app pytest
```

---

## 🔧 Variáveis de Ambiente

Crie um arquivo `.env` baseado no `.env.example`:

```env
FLASK_ENV=development
FLASK_SECRET_KEY=sua-chave-secreta-aqui
DATABASE_URL=sqlite:///db.sqlite3
```

> ⚠️ **Nunca** faça commit do arquivo `.env` real. Ele já está no `.gitignore`.

---

[← Voltar ao README principal](../README.md)
