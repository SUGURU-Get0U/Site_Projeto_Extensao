# isso é um comentário!S
# Convencao -> FUNCAO argumento
# escape é bom para windows

# Criado por Eduardo Ellwanger

# Ref: https://docs.docker.com/engine/reference/builder/#from




# syntax=docker/dockerfile:1

# escape=`

FROM python:3.11-slim

WORKDIR /app


# Instala o Poetry
RUN pip install poetry


# 4. Copia os arquivos de configuração do Poetry
COPY pyproject.toml poetry.lock* ./


# 5. Configura o Poetry para não criar ambientes virtuais dentro do container
# Como o container já é um ambiente isolado, não precisamos de venv interna.
RUN poetry config virtualenvs.create false

COPY pyproject.toml ./

#Instala as dependências listadas no pyproject.toml
RUN poetry install --no-root --no-interaction --no-ansi

# Copia o restante do código da sua aplicação
COPY . .

# 8. Expõe a porta que o Flask utiliza
# Ref: https://docs.docker.com/engine/reference/builder/#expose
EXPOSE 5000

# 9. Comando para iniciar a aplicação
CMD ["flask", "--app", "app.app", "run", "--host=0.0.0.0"]