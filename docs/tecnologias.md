# 🛠️ Tecnologias Utilizadas

[← Voltar ao README principal](../README.md)

---

## 📦 Stack Completa

### Backend

| Tecnologia | Versão recomendada | Função |
|---|---|---|
| **Python** | 3.11+ | Linguagem principal |
| **Flask** | 3.x | Framework web backend (rotas, lógica, API) |
| **Jinja2** | 3.x | Motor de templates server-side (SSR) |
| **Gunicorn** | 21.x | Servidor WSGI para produção |

> ⚠️ **Nota importante:** Flask é um framework **backend**. O Jinja2 é o motor de templates que gera o HTML enviado ao browser. CSS e JavaScript rodam no **lado do cliente (frontend)**. A arquitetura é **monolítica SSR** (Server-Side Rendering).

### Frontend (Client-side)

| Tecnologia | Função |
|---|---|
| **Jinja2 Templates** | Renderização de HTML no servidor |
| **CSS** | Estilização das páginas |
| **JavaScript** | Interatividade no browser |

### Gerenciamento de Pacotes

| Tecnologia | Função |
|---|---|
| **Poetry** | Gerenciador de dependências e ambientes virtuais |
| `pyproject.toml` | Arquivo de configuração do projeto |
| `poetry.lock` | Arquivo de lock para reprodutibilidade |

### Containerização

| Tecnologia | Função |
|---|---|
| **Docker** | Containerização da aplicação |
| **Docker Compose** | Orquestração dos serviços (app, banco, etc.) |

### Controle de Versão

| Tecnologia | Função |
|---|---|
| **Git** | Controle de versão distribuído |
| **GitHub** | Hospedagem do repositório remoto |
| **GitHub Desktop** | Interface gráfica para Git |

### Gestão do Projeto

| Tecnologia | Função |
|---|---|
| **Trello** | Kanban board de tarefas |
| **SCRUM** | Metodologia ágil com Sprints |

---

## ✅ Análise de Viabilidade

| Tecnologia | Viabilidade | Justificativa |
|---|---|---|
| Flask | 🟢 Alta | Leve e flexível; ideal para projetos de médio porte |
| Jinja2 | 🟢 Alta | Nativo do Flask, sem configuração adicional |
| CSS + JS vanilla | 🟢 Alta | Sem dependências extras; total controle |
| Poetry | 🟢 Alta | Reprodutibilidade garantida via `poetry.lock` |
| Docker + Compose | 🟢 Alta | Ambiente consistente em qualquer máquina |
| Gunicorn (WSGI) | 🟢 Alta | Padrão de mercado para Flask em produção |
| GitHub + Desktop | 🟢 Alta | Facilita colaboração para todos os perfis de dev |
| Trello + SCRUM | 🟢 Alta | Ágil e visual; ideal para equipes pequenas |

---

## ⚠️ Considerações Futuras

- Caso o projeto evolua para consumo por aplicativo mobile ou SPA (React/Vue), considere refatorar o backend para uma **API REST pura** separando completamente backend e frontend.
- Para escalabilidade, avalie substituir Gunicorn por **Uvicorn + ASGI** se houver necessidade de WebSockets ou alta concorrência assíncrona.

---

[← Voltar ao README principal](../README.md)
