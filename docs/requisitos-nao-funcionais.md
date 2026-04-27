# ⚙️ Requisitos Não Funcionais

[← Voltar ao README principal](../README.md)

---

## O que são?

Requisitos não funcionais descrevem **restrições e qualidades** que o sistema deve possuir. Diferente dos funcionais, eles não dizem *o que* o sistema faz, mas *como* ele deve se comportar. Devem ser sempre **mensuráveis**.

---

## 🗂️ Classificação (Sommerville, 2009)

```
Requisitos Não Funcionais
├── Requisitos do Produto
│   ├── Usabilidade
│   ├── Eficiência (Desempenho + Espaço)
│   ├── Confiabilidade
│   └── Portabilidade
├── Requisitos Organizacionais
│   ├── Entrega
│   ├── Implementação
│   └── Padrão
└── Requisitos Externos
    ├── Interoperabilidade
    ├── Éticos
    └── Legais (Privacidade e Segurança)
```

---

## 📌 Requisitos do Produto

### Usabilidade

| ID | Requisito |
|---|---|
| RNFU01 | O usuário deve ser capaz de utilizar as funcionalidades principais após 1 hora de uso sem treinamento formal. |
| RNFU02 | O usuário deve ser capaz de completar o fluxo principal em no máximo 5 cliques. |
| RNFU03 | O sistema deve exibir mensagens de erro claras e orientativas em qualquer tela. |

### Eficiência (Desempenho e Espaço)

| ID | Requisito |
|---|---|
| RNFE01 | O sistema deve responder a qualquer requisição em menos de 3 segundos em condições normais de uso. |
| RNFE02 | O sistema deve suportar ao menos 50 usuários simultâneos sem degradação de desempenho. |
| RNFE03 | A imagem Docker da aplicação não deve ultrapassar 500 MB. |

### Confiabilidade

| ID | Requisito |
|---|---|
| RNFC01 | O sistema deve ter disponibilidade mínima de 99% em horário de pico. |
| RNFC02 | Em caso de falha, o sistema deve se recuperar automaticamente em menos de 30 segundos. |
| RNFC03 | Os dados do usuário não devem ser perdidos em caso de falha inesperada. |

### Portabilidade

| ID | Requisito |
|---|---|
| RNFP01 | O sistema deve funcionar nos navegadores Chrome, Firefox e Edge (versões recentes). |
| RNFP02 | O sistema deve ser executável em qualquer sistema operacional que suporte Docker. |

---

## 📌 Requisitos Organizacionais

### Implementação

| ID | Requisito |
|---|---|
| RNFI01 | O sistema deve ser implementado em Python utilizando o framework Flask. |
| RNFI02 | O gerenciamento de dependências deve ser feito exclusivamente via Poetry. |
| RNFI03 | O código deve seguir o padrão PEP8 e ser documentado com docstrings. |

### Padrão

| ID | Requisito |
|---|---|
| RNFPA01 | O projeto deve utilizar Docker e Docker Compose para containerização. |
| RNFPA02 | O versionamento deve seguir o fluxo Git Flow (branches: main, develop, feature/*). |

---

## 📌 Requisitos Externos

### Legais e de Segurança

| ID | Requisito |
|---|---|
| RNFS01 | As senhas dos usuários devem ser armazenadas com hash (bcrypt ou Argon2). |
| RNFS02 | O acesso a rotas protegidas deve exigir autenticação válida. |
| RNFS03 | O sistema deve estar em conformidade com a LGPD no tratamento de dados pessoais. |

---

## 📎 Referência

Baseado nas aulas de *Requisitos de Software — Elicitação e Análise de Requisitos, Parte 02* (Andrey Cabral) e Sommerville (2009).

---

[← Voltar ao README principal](../README.md)
