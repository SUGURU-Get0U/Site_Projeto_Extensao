# SXF Sistema — Triagem da Síndrome do X Frágil

Sistema web para apoiar profissionais de saúde na **triagem da Síndrome do X Frágil (SXF)**.
A partir de um checklist de sintomas, o sistema calcula um *score* de risco e indica se o
paciente deve ser **encaminhado para teste genético**. Inclui cadastro de pacientes, histórico
de avaliações, relatórios e exportação de dados.

> Projeto de extensão acadêmico desenvolvido para o **Instituto Buko Kaesemodel (IBK)**.

---

## Como funciona

1. O profissional cadastra o **paciente** (com dados protegidos por criptografia).
2. Aplica o **checklist de sintomas** durante a avaliação.
3. O sistema calcula o **score** com base em pesos derivados de um modelo *Random Forest*
   (coorte IBK 2018–2023, 419 indivíduos com mutação completa):

   ```
   Score = Σ (Peso_sintoma × Presente)
   ```

   Cada sintoma tem peso diferente para **homens** e **mulheres**, e há um **limiar**
   por gênero (0,56 para homens / 0,55 para mulheres). Se o score atinge o limiar,
   o sistema **recomenda o teste genético**.
4. As avaliações ficam registradas e podem ser consultadas em **relatórios** filtráveis
   (por data, sexo, status, recomendação) e exportadas em **CSV**.

A lógica de cálculo está em [app/calculo_back_end.py](app/calculo_back_end.py).

---

## Stack / Tecnologias

| Camada | Tecnologia |
|--------|------------|
| Linguagem | Python 3.9+ |
| Framework web | Flask 3 |
| ORM / Banco | Flask-SQLAlchemy (SQLite local; MySQL via `DATABASE_URL`) |
| Autenticação | Flask-Login + Flask-Bcrypt (hash de senha) |
| Criptografia | `cryptography` (Fernet) para campos sensíveis (CPF, telefone, e-mail) |
| Templates | Jinja2 (HTML), CSS puro |
| Deploy | Docker + Docker Compose |

### Controle de acesso (papéis)

- **admin_master** — acesso total a todas as instituições
- **admin** — administrador da instituição
- **profissional** — cadastra pacientes e aplica avaliações
- **paciente** — acessa apenas o próprio histórico

---

## Estrutura do projeto

```
app/
├── app.py              # criação do Flask, config, bootstrap do banco
├── models.py           # modelos (Instituicao, Usuario, Paciente, Avaliacao, Sintoma...)
├── views.py            # rotas principais (dashboard, pacientes, avaliações)
├── auth.py             # login, logout, controle de acesso
├── admin.py            # gestão de usuários e instituições
├── relatorios.py       # relatórios e exportação CSV
├── calculo_back_end.py # pesos dos sintomas e cálculo do score
├── templates/          # páginas Jinja2 (base.html público, base_interno.html interno)
└── static/             # CSS e JS
popular_banco.py        # popula o banco com dados de exemplo
iniciar.ps1             # inicia o app com a chave de criptografia correta
```

---

## Como rodar (local)

Pré-requisitos: **Python 3.9+** instalado.

```bash
# 1. Instalar dependências
pip install flask flask-sqlalchemy flask-login flask-bcrypt cryptography pymysql python-dotenv

# 2. (opcional) Popular o banco com dados de exemplo
python popular_banco.py
```

### Iniciar o servidor

**Windows (recomendado):** use o script, que já define a chave de criptografia correta:

```powershell
.\iniciar.ps1
```

**Manualmente** (defina a chave antes, senão os campos criptografados aparecem embaralhados):

```bash
# Linux / macOS
export ENCRYPTION_KEY="MUk5mne5GP5v6p9Ao7YywJP9w0weCBCgBoOCc4LaJhk="
export FLASK_SECRET_KEY="sxf-secret-fixo-2026"
python -m flask --app app.app run
```

Acesse: **http://127.0.0.1:5000**

### Login padrão

| Campo | Valor |
|-------|-------|
| E-mail | `admin@sxf.com` |
| Senha | `Admin@2026` |

Os profissionais criados pelo `popular_banco.py` usam a senha `Senha@2026`.

---

## Banco de dados

Por padrão usa **SQLite** (`sxf_local.db`), criado automaticamente na primeira execução.
Para usar **MySQL**, defina a variável de ambiente:

```bash
export DATABASE_URL="mysql+pymysql://usuario:senha@host:3306/sxf_checklist"
```

> ⚠️ Os campos CPF, telefone e e-mail do responsável são **criptografados** no banco.
> Use sempre a mesma `ENCRYPTION_KEY` para conseguir lê-los.

---

## Observações

- Sistema desenvolvido para fins **educacionais / de triagem**, não substitui diagnóstico médico.
- Os pesos e limiares são baseados em um estudo específico e devem ser validados clinicamente.
