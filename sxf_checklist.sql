-- ============================================================
--  SXF CHECKLIST SITE — Banco de Dados Completo
--  Síndrome do X Frágil — Sistema de Triagem Clínica
--  MySQL 8.0+
--  Atualizado em: 2026
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ------------------------------------------------------------
--  BANCO DE DADOS
-- ------------------------------------------------------------
DROP DATABASE IF EXISTS sxf_checklist;
CREATE DATABASE sxf_checklist
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sxf_checklist;


-- ============================================================
--  1. ROLES — Perfis de acesso do sistema
-- ============================================================
CREATE TABLE roles (
    id          TINYINT UNSIGNED    NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(50)         NOT NULL,
    descricao   VARCHAR(255)        NOT NULL,
    criado_em   DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_role_nome (nome)
) ENGINE=InnoDB COMMENT='Perfis de acesso';

INSERT INTO roles (id, nome, descricao) VALUES
    (1, 'admin_master', 'Administrador com acesso total ao sistema'),
    (2, 'admin',        'Administrador institucional'),
    (3, 'profissional', 'Profissional de saúde autorizado a cadastrar pacientes e realizar avaliações'),
    (4, 'paciente',     'Paciente — acesso somente ao próprio histórico de avaliações');


-- ============================================================
--  2. ESPECIALIDADES — Catálogo de especialidades médicas
-- ============================================================
CREATE TABLE especialidades (
    id      SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    nome    VARCHAR(100)        NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_especialidade_nome (nome)
) ENGINE=InnoDB COMMENT='Especialidades médicas/da saúde';

INSERT INTO especialidades (nome) VALUES
    ('Médico Generalista'),
    ('Geneticista'),
    ('Neurologista'),
    ('Pediatra'),
    ('Psiquiatra'),
    ('Psicólogo'),
    ('Enfermeiro'),
    ('Fonoaudiólogo'),
    ('Neuropediatra'),
    ('Terapeuta Ocupacional');


-- ============================================================
--  3. INSTITUIÇÕES (Hospitais / Clínicas)
-- ============================================================
CREATE TABLE instituicoes (
    id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(200)    NOT NULL,
    cnpj          VARCHAR(18)     NULL,
    endereco      VARCHAR(255)    NULL,
    cidade        VARCHAR(100)    NULL,
    estado        CHAR(2)         NULL,
    cep           VARCHAR(10)     NULL,
    telefone      VARCHAR(20)     NULL,
    email         VARCHAR(150)    NULL,
    ativa         TINYINT(1)      NOT NULL DEFAULT 1,
    criado_em     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_inst_cnpj (cnpj),
    INDEX idx_inst_cidade (cidade),
    INDEX idx_inst_ativa  (ativa)
) ENGINE=InnoDB COMMENT='Instituições de saúde parceiras (hospitais e clínicas)';

INSERT INTO instituicoes (nome, cnpj, endereco, cidade, estado, cep, telefone, email) VALUES
    ('Hospital das Clínicas - UFPR',  '75.457.040/0001-29', 'R. Padre Camargo, 280 - Alto da Glória', 'Curitiba',  'PR', '80060-240', '(41) 3360-1800', 'hc@ufpr.br'),
    ('Instituto Genética Brasil',      '12.345.678/0001-00', 'Av. Brasil, 1500 - Centro',               'São Paulo', 'SP', '01310-100', '(11) 3000-0000', 'contato@igbrasil.com.br'),
    ('Clínica de Neurologia Infantil', '98.765.432/0001-00', 'R. das Flores, 200 - Batel',              'Curitiba',  'PR', '80420-120', '(41) 3333-4444', 'neuroped@clinica.com.br');


-- ============================================================
--  4. USUÁRIOS — Tabela central de autenticação
-- ============================================================
-- NOTA SOBRE CRIPTOGRAFIA:
--   senha_hash  → bcrypt (nunca texto plano)
--   Campos sensíveis de pacientes → Fernet AES-128-CBC (Python)
-- ============================================================
CREATE TABLE usuarios (
    id                  INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    role_id             TINYINT UNSIGNED    NOT NULL,
    -- Vínculo com a instituição onde o profissional trabalha
    -- NULL = admin_master (acesso a todas) ou usuário sem instituição
    instituicao_id      INT UNSIGNED        NULL,
    -- Vínculo com registro de paciente (preenchido apenas quando role = paciente)
    paciente_id         INT UNSIGNED        NULL,
    nome_completo       VARCHAR(150)        NOT NULL,
    email               VARCHAR(150)        NOT NULL,
    senha_hash          VARCHAR(255)        NOT NULL   COMMENT 'bcrypt hash',
    ativo               TINYINT(1)          NOT NULL DEFAULT 1,
    email_verificado    TINYINT(1)          NOT NULL DEFAULT 0,
    token_verificacao   VARCHAR(100)        NULL,
    token_reset_senha   VARCHAR(100)        NULL,
    token_reset_expira  DATETIME            NULL,
    ultimo_login        DATETIME            NULL,
    tentativas_login    TINYINT UNSIGNED    NOT NULL DEFAULT 0,
    bloqueado_ate       DATETIME            NULL,
    criado_em           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_usuario_email (email),
    INDEX idx_usuario_role         (role_id),
    INDEX idx_usuario_ativo        (ativo),
    INDEX idx_usuario_instituicao  (instituicao_id),
    CONSTRAINT fk_usuario_role        FOREIGN KEY (role_id)        REFERENCES roles       (id) ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_instituicao FOREIGN KEY (instituicao_id) REFERENCES instituicoes(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Tabela central de autenticação de todos os usuários';


-- ============================================================
--  5. PROFISSIONAIS DE SAÚDE
-- ============================================================
CREATE TABLE profissionais (
    id                      INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    usuario_id              INT UNSIGNED        NOT NULL,
    especialidade_id        SMALLINT UNSIGNED   NOT NULL,
    registro_profissional   VARCHAR(30)         NOT NULL,
    tipo_registro           VARCHAR(20)         NOT NULL DEFAULT 'CRM'
                            COMMENT 'CRM, COREN, CRF, CFP, CREFONO, etc.',
    estado_registro         CHAR(2)             NOT NULL,
    telefone                VARCHAR(20)         NULL,
    bio                     TEXT                NULL,
    aprovado                TINYINT(1)          NOT NULL DEFAULT 0
                            COMMENT 'Admin precisa aprovar o cadastro',
    aprovado_por            INT UNSIGNED        NULL,
    aprovado_em             DATETIME            NULL,
    criado_em               DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em           DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_prof_registro (registro_profissional, tipo_registro, estado_registro),
    INDEX idx_prof_usuario       (usuario_id),
    INDEX idx_prof_especialidade (especialidade_id),
    INDEX idx_prof_aprovado      (aprovado),
    CONSTRAINT fk_prof_usuario        FOREIGN KEY (usuario_id)       REFERENCES usuarios      (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_prof_especialidade  FOREIGN KEY (especialidade_id) REFERENCES especialidades(id) ON UPDATE CASCADE,
    CONSTRAINT fk_prof_aprovado_por   FOREIGN KEY (aprovado_por)     REFERENCES usuarios      (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Dados profissionais dos usuários com papel de profissional de saúde';


-- ============================================================
--  6. PROFISSIONAL × INSTITUIÇÃO  (N:M)
-- ============================================================
CREATE TABLE profissional_instituicao (
    profissional_id INT UNSIGNED NOT NULL,
    instituicao_id  INT UNSIGNED NOT NULL,
    cargo           VARCHAR(80)  NULL     COMMENT 'Ex: Coordenador, Plantonista',
    data_inicio     DATE         NULL,
    data_fim        DATE         NULL     COMMENT 'NULL = vínculo ativo',
    PRIMARY KEY (profissional_id, instituicao_id),
    INDEX idx_pi_instituicao (instituicao_id),
    CONSTRAINT fk_pi_profissional FOREIGN KEY (profissional_id) REFERENCES profissionais(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pi_instituicao  FOREIGN KEY (instituicao_id)  REFERENCES instituicoes  (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Vínculo entre profissionais e instituições onde atuam';


-- ============================================================
--  7. ADMINS — perfil extra para role admin / admin_master
-- ============================================================
CREATE TABLE admins (
    id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    usuario_id   INT UNSIGNED  NOT NULL,
    departamento VARCHAR(100)  NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admin_usuario (usuario_id),
    CONSTRAINT fk_admin_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Dados adicionais de administradores';


-- ============================================================
--  8. SESSÕES DE USUÁRIO
-- ============================================================
CREATE TABLE sessoes (
    id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id    INT UNSIGNED    NOT NULL,
    token_sessao  VARCHAR(512)    NOT NULL,
    ip_origem     VARCHAR(45)     NULL,
    user_agent    VARCHAR(512)    NULL,
    criado_em     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_em     DATETIME        NOT NULL,
    encerrada     TINYINT(1)      NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    INDEX idx_sessao_usuario (usuario_id),
    INDEX idx_sessao_token   (token_sessao(64)),
    INDEX idx_sessao_expira  (expira_em),
    CONSTRAINT fk_sessao_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Controle de sessões ativas dos usuários';


-- ============================================================
--  9. PACIENTES
--  CRIPTOGRAFIA: cpf, telefone_responsavel, email_responsavel
--  são criptografados em Python (Fernet) antes de salvar.
--  O tipo TEXT acomoda o token Fernet (~100-200 chars).
-- ============================================================
CREATE TABLE pacientes (
    id                      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    -- Instituição a que este paciente pertence (herdada do profissional que cadastrou)
    instituicao_id          INT UNSIGNED    NULL,
    nome_completo           VARCHAR(150)    NOT NULL,
    data_nascimento         DATE            NOT NULL,
    genero                  CHAR(1)         NOT NULL   COMMENT 'M = Masculino, F = Feminino',
    -- Campo criptografado com Fernet (AES-128-CBC + HMAC-SHA256)
    cpf                     TEXT            NULL       COMMENT 'Armazenado criptografado',
    cpf_hash                VARCHAR(64)     NULL,
    nome_responsavel        VARCHAR(150)    NULL,
    -- Campos criptografados com Fernet
    telefone_responsavel    TEXT            NULL       COMMENT 'Armazenado criptografado',
    email_responsavel       TEXT            NULL       COMMENT 'Armazenado criptografado',
    observacoes             TEXT            NULL,
    cadastrado_por          INT UNSIGNED    NOT NULL   COMMENT 'usuario_id do profissional que cadastrou',
    ativo                   TINYINT(1)      NOT NULL DEFAULT 1,
    criado_em               DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_paciente_nome       (nome_completo),
    INDEX idx_paciente_genero     (genero),
    INDEX idx_paciente_cadpor     (cadastrado_por),
    INDEX idx_paciente_instituicao(instituicao_id),
    INDEX idx_paciente_ativo      (ativo),
    UNIQUE KEY uq_paciente_cpf_hash (cpf_hash),
    CONSTRAINT fk_paciente_cadastrado_por FOREIGN KEY (cadastrado_por)  REFERENCES usuarios   (id) ON UPDATE CASCADE,
    CONSTRAINT fk_paciente_instituicao    FOREIGN KEY (instituicao_id)  REFERENCES instituicoes(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_paciente_genero CHECK (genero IN ('M', 'F'))
) ENGINE=InnoDB COMMENT='Pacientes cadastrados para triagem de SXF';

-- Após criar a tabela pacientes, adicionar a FK de usuarios.paciente_id
ALTER TABLE usuarios
    ADD CONSTRAINT fk_usuario_paciente
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id) ON DELETE SET NULL ON UPDATE CASCADE;


-- ============================================================
--  10. SINTOMAS — Catálogo com pesos por gênero
--  Score = Σ (peso_genero_j × X_ij)  |  limiar H=0.56 / M=0.55
-- ============================================================
CREATE TABLE sintomas (
    id              SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    codigo          VARCHAR(20)         NOT NULL    COMMENT 'Ex: SXF_001',
    nome            VARCHAR(120)        NOT NULL,
    descricao       TEXT                NULL,
    peso_masculino  DECIMAL(5,4)        NOT NULL DEFAULT 0.0000,
    peso_feminino   DECIMAL(5,4)        NOT NULL DEFAULT 0.0000,
    ativo           TINYINT(1)          NOT NULL DEFAULT 1,
    ordem           TINYINT UNSIGNED    NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uq_sintoma_codigo (codigo),
    INDEX idx_sintoma_ativo (ativo)
) ENGINE=InnoDB COMMENT='Catálogo dos 12 sintomas do checklist SXF com pesos clínicos';

INSERT INTO sintomas (codigo, nome, descricao, peso_masculino, peso_feminino, ordem) VALUES
    ('SXF_001', 'Deficiência Intelectual',
     'Comprometimento cognitivo observável, com QI abaixo do esperado para idade.',
     0.3200, 0.2000, 1),
    ('SXF_002', 'Face Alongada / Orelhas de Abano',
     'Características faciais típicas: face estreita e alongada, orelhas grandes e proeminentes.',
     0.2900, 0.0900, 2),
    ('SXF_003', 'Macroorquidismo',
     'Aumento do volume testicular. Irrelevante para mulheres.',
     0.2600, 0.0000, 3),
    ('SXF_004', 'Hipermobilidade Articular',
     'Articulações com amplitude de movimento acima do normal.',
     0.1900, 0.0400, 4),
    ('SXF_005', 'Dificuldades de Aprendizagem',
     'Dificuldades específicas em leitura, escrita ou matemática.',
     0.1800, 0.2800, 5),
    ('SXF_006', 'Déficit de Atenção',
     'Dificuldade persistente em manter atenção, fácil distração.',
     0.1700, 0.1200, 6),
    ('SXF_007', 'Movimentos Repetitivos (Estereotipias)',
     'Comportamentos motores repetitivos.',
     0.1700, 0.0500, 7),
    ('SXF_008', 'Atraso na Fala',
     'Desenvolvimento da linguagem abaixo do esperado para a faixa etária.',
     0.1400, 0.0100, 8),
    ('SXF_009', 'Hiperatividade',
     'Atividade motora excessiva e impulsividade.',
     0.1200, 0.0400, 9),
    ('SXF_010', 'Evita Contato Visual',
     'Dificuldade ou recusa em manter contato visual direto.',
     0.0600, 0.0800, 10),
    ('SXF_011', 'Evita Contato Físico',
     'Sensibilidade tátil aumentada, rejeição a abraços ou toque.',
     0.0400, 0.0700, 11),
    ('SXF_012', 'Agressividade',
     'Episódios de agressão verbal ou física.',
     0.0100, 0.0200, 12);


-- ============================================================
--  11. AVALIAÇÕES (Checklist)
-- ============================================================
CREATE TABLE avaliacoes (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    paciente_id     INT UNSIGNED    NOT NULL,
    usuario_id      INT UNSIGNED    NULL     COMMENT 'usuario_id do profissional',
    instituicao_id  INT UNSIGNED    NULL     COMMENT 'Instituição onde foi realizada',
    score           DECIMAL(6,4)    NOT NULL DEFAULT 0.0000,
    limiar_aplicado DECIMAL(5,4)    NOT NULL COMMENT '0.56 para H, 0.55 para F',
    recomenda_teste TINYINT(1)      NOT NULL DEFAULT 0,
    status          ENUM('rascunho','finalizada','revisada','cancelada')
                    NOT NULL DEFAULT 'rascunho',
    observacoes     TEXT            NULL,
    realizada_em    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finalizada_em   DATETIME        NULL,
    criado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_aval_paciente    (paciente_id),
    INDEX idx_aval_usuario     (usuario_id),
    INDEX idx_aval_instituicao (instituicao_id),
    INDEX idx_aval_status      (status),
    INDEX idx_aval_realizada   (realizada_em),
    INDEX idx_aval_recomenda   (recomenda_teste),
    CONSTRAINT fk_aval_paciente    FOREIGN KEY (paciente_id)    REFERENCES pacientes   (id) ON UPDATE CASCADE,
    CONSTRAINT fk_aval_usuario     FOREIGN KEY (usuario_id)     REFERENCES usuarios    (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_aval_instituicao FOREIGN KEY (instituicao_id) REFERENCES instituicoes(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Avaliações realizadas — cada linha = uma sessão de triagem';


-- ============================================================
--  12. AVALIAÇÃO × SINTOMA
-- ============================================================
CREATE TABLE avaliacao_sintomas (
    avaliacao_id    INT UNSIGNED        NOT NULL,
    sintoma_id      SMALLINT UNSIGNED   NOT NULL,
    presente        TINYINT(1)          NOT NULL DEFAULT 0,
    contribuicao    DECIMAL(5,4)        NOT NULL DEFAULT 0.0000,
    PRIMARY KEY (avaliacao_id, sintoma_id),
    INDEX idx_as_sintoma (sintoma_id),
    CONSTRAINT fk_as_avaliacao FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_as_sintoma   FOREIGN KEY (sintoma_id)   REFERENCES sintomas  (id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Resultado binário de cada sintoma para cada avaliação';


-- ============================================================
--  13. HISTÓRICO DE ALTERAÇÕES NAS AVALIAÇÕES
-- ============================================================
CREATE TABLE avaliacao_historico (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    avaliacao_id    INT UNSIGNED    NOT NULL,
    alterado_por    INT UNSIGNED    NOT NULL,
    tipo_alteracao  ENUM('criacao','edicao_sintoma','edicao_obs','status','cancelamento')
                    NOT NULL DEFAULT 'edicao_sintoma',
    campo_alterado  VARCHAR(80)     NULL,
    valor_anterior  TEXT            NULL,
    valor_novo      TEXT            NULL,
    motivo          TEXT            NULL,
    ip_origem       VARCHAR(45)     NULL,
    criado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_ah_avaliacao (avaliacao_id),
    INDEX idx_ah_alterado  (alterado_por),
    INDEX idx_ah_criado    (criado_em),
    CONSTRAINT fk_ah_avaliacao FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ah_alterado  FOREIGN KEY (alterado_por) REFERENCES usuarios  (id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Auditoria completa de todas as alterações em avaliações';


-- ============================================================
--  14. LOG DE AUDITORIA GERAL
-- ============================================================
CREATE TABLE audit_log (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id  INT UNSIGNED    NULL,
    acao        VARCHAR(100)    NOT NULL,
    tabela      VARCHAR(80)     NULL,
    registro_id INT UNSIGNED    NULL,
    descricao   TEXT            NULL,
    ip_origem   VARCHAR(45)     NULL,
    user_agent  VARCHAR(512)    NULL,
    criado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_audit_usuario (usuario_id),
    INDEX idx_audit_acao    (acao),
    INDEX idx_audit_criado  (criado_em),
    CONSTRAINT fk_audit_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Log de auditoria de todas as ações relevantes no sistema';


-- ============================================================
--  15. BACKUP LOG
-- ============================================================
CREATE TABLE backup_log (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    iniciado_em     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    concluido_em    DATETIME        NULL,
    status          ENUM('iniciado','concluido','falhou') NOT NULL DEFAULT 'iniciado',
    tamanho_bytes   BIGINT UNSIGNED NULL,
    caminho_arquivo VARCHAR(512)    NULL,
    observacoes     TEXT            NULL,
    PRIMARY KEY (id),
    INDEX idx_backup_status   (status),
    INDEX idx_backup_iniciado (iniciado_em)
) ENGINE=InnoDB COMMENT='Registro de execução dos backups diários automáticos';


-- ============================================================
--  16. CONFIGURAÇÕES DO SISTEMA
-- ============================================================
CREATE TABLE configuracoes (
    chave         VARCHAR(80)  NOT NULL,
    valor         TEXT         NOT NULL,
    descricao     VARCHAR(255) NULL,
    atualizado_em DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (chave)
) ENGINE=InnoDB COMMENT='Configurações globais do sistema';

INSERT INTO configuracoes (chave, valor, descricao) VALUES
    ('limiar_score_masculino', '0.56',  'Limiar de corte do score SXF para pacientes do sexo masculino'),
    ('limiar_score_feminino',  '0.55',  'Limiar de corte do score SXF para pacientes do sexo feminino'),
    ('sessao_expiracao_horas', '8',     'Tempo em horas até expirar a sessão do usuário'),
    ('max_tentativas_login',   '5',     'Número máximo de tentativas de login antes de bloquear'),
    ('bloqueio_login_minutos', '30',    'Tempo em minutos de bloqueio após tentativas excedidas'),
    ('backup_hora',            '23:00', 'Hora diária para execução do backup automático'),
    ('nome_sistema',           'SXF Checklist',               'Nome exibido no sistema'),
    ('email_suporte',          'suporte@sxfchecklist.com.br', 'E-mail de suporte técnico');


-- ============================================================
--  STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- Calcular e salvar o score de uma avaliação
CREATE PROCEDURE sp_calcular_score(IN p_avaliacao_id INT UNSIGNED)
BEGIN
    DECLARE v_genero    CHAR(1);
    DECLARE v_score     DECIMAL(6,4);
    DECLARE v_limiar    DECIMAL(5,4);
    DECLARE v_recomenda TINYINT(1);

    SELECT p.genero INTO v_genero
    FROM   avaliacoes a
    JOIN   pacientes  p ON p.id = a.paciente_id
    WHERE  a.id = p_avaliacao_id LIMIT 1;

    SELECT IFNULL(SUM(
        CASE v_genero
            WHEN 'M' THEN s.peso_masculino * asy.presente
            WHEN 'F' THEN s.peso_feminino  * asy.presente
            ELSE 0
        END), 0)
    INTO v_score
    FROM avaliacao_sintomas asy
    JOIN sintomas s ON s.id = asy.sintoma_id
    WHERE asy.avaliacao_id = p_avaliacao_id;

    UPDATE avaliacao_sintomas asy
    JOIN   sintomas s ON s.id = asy.sintoma_id
    SET    asy.contribuicao = CASE v_genero
                                  WHEN 'M' THEN s.peso_masculino * asy.presente
                                  WHEN 'F' THEN s.peso_feminino  * asy.presente
                                  ELSE 0
                              END
    WHERE  asy.avaliacao_id = p_avaliacao_id;

    SELECT CASE v_genero
               WHEN 'M' THEN (SELECT CAST(valor AS DECIMAL(5,4)) FROM configuracoes WHERE chave = 'limiar_score_masculino')
               WHEN 'F' THEN (SELECT CAST(valor AS DECIMAL(5,4)) FROM configuracoes WHERE chave = 'limiar_score_feminino')
               ELSE 0.56
           END INTO v_limiar;

    SET v_recomenda = IF(v_score >= v_limiar, 1, 0);

    UPDATE avaliacoes
    SET    score = v_score, limiar_aplicado = v_limiar, recomenda_teste = v_recomenda
    WHERE  id = p_avaliacao_id;

    SELECT v_score AS score, v_limiar AS limiar, v_recomenda AS recomenda_teste;
END$$


-- Finalizar uma avaliação
CREATE PROCEDURE sp_finalizar_avaliacao(
    IN p_avaliacao_id INT UNSIGNED,
    IN p_usuario_id   INT UNSIGNED,
    IN p_ip           VARCHAR(45)
)
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM avaliacoes WHERE id = p_avaliacao_id;

    IF v_status = 'rascunho' THEN
        CALL sp_calcular_score(p_avaliacao_id);
        UPDATE avaliacoes SET status = 'finalizada', finalizada_em = NOW() WHERE id = p_avaliacao_id;

        INSERT INTO avaliacao_historico (avaliacao_id, alterado_por, tipo_alteracao, campo_alterado, valor_anterior, valor_novo, ip_origem)
        VALUES (p_avaliacao_id, p_usuario_id, 'status', 'status', 'rascunho', 'finalizada', p_ip);

        INSERT INTO audit_log (usuario_id, acao, tabela, registro_id, descricao, ip_origem)
        VALUES (p_usuario_id, 'FINALIZAR_AVALIACAO', 'avaliacoes', p_avaliacao_id,
                CONCAT('Avaliação #', p_avaliacao_id, ' finalizada'), p_ip);

        SELECT 'Avaliação finalizada com sucesso.' AS mensagem;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avaliação não está em rascunho.';
    END IF;
END$$


-- Histórico completo de avaliações de um paciente
CREATE PROCEDURE sp_historico_paciente(IN p_paciente_id INT UNSIGNED)
BEGIN
    SELECT
        a.id            AS avaliacao_id,
        a.realizada_em,
        a.status,
        a.score,
        a.limiar_aplicado,
        a.recomenda_teste,
        a.observacoes,
        u.nome_completo AS profissional_nome,
        IFNULL(i.nome, '—') AS instituicao
    FROM   avaliacoes  a
    LEFT JOIN usuarios  u ON u.id = a.usuario_id
    LEFT JOIN instituicoes i ON i.id = a.instituicao_id
    WHERE  a.paciente_id = p_paciente_id
    ORDER  BY a.realizada_em DESC;
END$$


-- Dashboard do Admin
CREATE PROCEDURE sp_dashboard_admin()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM pacientes WHERE ativo = 1)                          AS total_pacientes,
        (SELECT COUNT(*) FROM avaliacoes WHERE status = 'finalizada')             AS total_avaliacoes,
        (SELECT COUNT(*) FROM avaliacoes WHERE recomenda_teste = 1)               AS total_recomendacoes,
        (SELECT COUNT(*) FROM usuarios WHERE role_id = 3 AND ativo = 1)          AS profissionais_ativos,
        (SELECT COUNT(*) FROM avaliacoes WHERE DATE(realizada_em) = CURDATE())    AS avaliacoes_hoje,
        (SELECT ROUND(AVG(score),4) FROM avaliacoes WHERE status = 'finalizada')  AS score_medio;
END$$


-- Aprovar cadastro de profissional
CREATE PROCEDURE sp_aprovar_profissional(
    IN p_profissional_id INT UNSIGNED,
    IN p_admin_id        INT UNSIGNED
)
BEGIN
    UPDATE profissionais
    SET    aprovado = 1, aprovado_por = p_admin_id, aprovado_em = NOW()
    WHERE  id = p_profissional_id;

    UPDATE usuarios u
    JOIN   profissionais pr ON pr.usuario_id = u.id
    SET    u.ativo = 1
    WHERE  pr.id = p_profissional_id;

    INSERT INTO audit_log (usuario_id, acao, tabela, registro_id, descricao)
    VALUES (p_admin_id, 'APROVACAO_PROFISSIONAL', 'profissionais', p_profissional_id,
            CONCAT('Profissional #', p_profissional_id, ' aprovado pelo admin #', p_admin_id));

    SELECT 'Profissional aprovado com sucesso.' AS mensagem;
END$$

DELIMITER ;


-- ============================================================
--  VIEWS ÚTEIS
-- ============================================================

CREATE OR REPLACE VIEW vw_avaliacoes_completas AS
SELECT
    a.id                AS avaliacao_id,
    a.realizada_em,
    a.finalizada_em,
    a.status,
    a.score,
    a.limiar_aplicado,
    a.recomenda_teste,
    a.observacoes,
    p.id                AS paciente_id,
    p.nome_completo     AS paciente_nome,
    TIMESTAMPDIFF(YEAR, p.data_nascimento, CURDATE()) AS paciente_idade,
    p.genero            AS paciente_genero,
    u.id                AS usuario_id,
    u.nome_completo     AS profissional_nome,
    IFNULL(i.nome, '—') AS instituicao_nome
FROM       avaliacoes   a
JOIN       pacientes    p ON p.id = a.paciente_id
LEFT JOIN  usuarios     u ON u.id = a.usuario_id
LEFT JOIN  instituicoes i ON i.id = a.instituicao_id;


CREATE OR REPLACE VIEW vw_sintomas_positivos AS
SELECT
    asy.avaliacao_id,
    s.codigo,
    s.nome          AS sintoma,
    asy.presente,
    asy.contribuicao,
    a.paciente_id,
    a.usuario_id
FROM avaliacao_sintomas asy
JOIN sintomas   s ON s.id = asy.sintoma_id
JOIN avaliacoes a ON a.id = asy.avaliacao_id
WHERE asy.presente = 1;


CREATE OR REPLACE VIEW vw_profissionais_instituicoes AS
SELECT
    u.id            AS usuario_id,
    u.nome_completo,
    u.email,
    u.ativo,
    r.nome          AS role,
    IFNULL(i.nome, '—') AS instituicao
FROM     usuarios     u
JOIN     roles        r ON r.id = u.role_id
LEFT JOIN instituicoes i ON i.id = u.instituicao_id
WHERE r.id IN (2, 3);


-- ============================================================
--  TRIGGERS
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_paciente_insert
AFTER INSERT ON pacientes
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (usuario_id, acao, tabela, registro_id, descricao)
    VALUES (NEW.cadastrado_por, 'CADASTRO_PACIENTE', 'pacientes', NEW.id,
            CONCAT('Paciente "', NEW.nome_completo, '" cadastrado'));
END$$


CREATE TRIGGER trg_avaliacao_insert
AFTER INSERT ON avaliacoes
FOR EACH ROW
BEGIN
    INSERT INTO avaliacao_historico (avaliacao_id, alterado_por, tipo_alteracao, campo_alterado, valor_novo)
    VALUES (NEW.id, IFNULL(NEW.usuario_id, 0), 'criacao', 'status', 'rascunho');
END$$


CREATE TRIGGER trg_bloquear_usuario
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    DECLARE v_max_tentativas  INT;
    DECLARE v_minutos_bloqueio INT;

    SELECT CAST(valor AS UNSIGNED) INTO v_max_tentativas   FROM configuracoes WHERE chave = 'max_tentativas_login';
    SELECT CAST(valor AS UNSIGNED) INTO v_minutos_bloqueio FROM configuracoes WHERE chave = 'bloqueio_login_minutos';

    IF NEW.tentativas_login >= v_max_tentativas AND OLD.tentativas_login < v_max_tentativas THEN
        SET NEW.bloqueado_ate = DATE_ADD(NOW(), INTERVAL v_minutos_bloqueio MINUTE);
    END IF;

    IF NEW.tentativas_login = 0 THEN
        SET NEW.bloqueado_ate = NULL;
    END IF;
END$$

DELIMITER ;


-- ============================================================
--  EVENTO: BACKUP DIÁRIO
-- ============================================================
SET GLOBAL event_scheduler = ON;

DELIMITER $$
CREATE EVENT evt_backup_diario
ON SCHEDULE EVERY 1 DAY
STARTS (DATE(NOW()) + INTERVAL 23 HOUR)
DO
BEGIN
    INSERT INTO backup_log (status, observacoes)
    VALUES ('iniciado', 'Backup automático agendado iniciado pelo event scheduler');
END$$
DELIMITER ;


-- ============================================================
--  DADOS INICIAIS
-- ============================================================
-- Senhas de exemplo (bcrypt rounds=12):
--   admin@sxf.com          → Admin@2026
--   dr.carlos@sxf.com      → SXFprof@2026!
--   dra.ana@sxf.com        → SXFprof@2026!
-- ============================================================

INSERT INTO usuarios (id, role_id, instituicao_id, nome_completo, email, senha_hash, ativo, email_verificado) VALUES
    (1, 1, NULL, 'Administrador Master SXF',
     'admin@sxf.com',
     '$2b$12$KixMHDnZY9Q6xMb8EWdROuGTEQ8A4v7C3NxNYQzfAa1gORNEPHVGi',
     1, 1);

INSERT INTO admins (usuario_id, departamento) VALUES
    (1, 'Tecnologia da Informação'),
    (2, 'Administração Geral');

INSERT INTO profissionais (usuario_id, especialidade_id, registro_profissional, tipo_registro, estado_registro, telefone, aprovado, aprovado_por, aprovado_em) VALUES
    (3, 2, 'CRM/PR-123456', 'CRM', 'PR', '(41) 99999-0001', 1, 1, NOW()),
    (4, 3, 'CRM/PR-234567', 'CRM', 'PR', '(41) 99999-0002', 1, 1, NOW());

INSERT INTO profissional_instituicao (profissional_id, instituicao_id, cargo, data_inicio) VALUES
    (1, 1, 'Geneticista Responsável', '2023-01-10'),
    (2, 1, 'Neurologista',            '2022-06-15');

-- Pacientes de exemplo (CPF, telefone e email do responsável seriam criptografados pelo Python)
INSERT INTO pacientes (instituicao_id, nome_completo, data_nascimento, genero, nome_responsavel, observacoes, cadastrado_por) VALUES
    (1, 'Lucas Ferreira Almeida', '2015-03-12', 'M', 'Maria Almeida',  'Criança com histórico familiar positivo para SXF.', 3),
    (1, 'Sofia Pereira Santos',   '2018-07-22', 'F', 'Pedro Santos',   'Encaminhada pelo pediatra com suspeita de atraso.', 4),
    (1, 'Gabriel Torres José', '2013-09-18', 'M', 'Luana Machado',  'Diagnóstico de TDAH prévio.', 3);


-- ============================================================
--  ÍNDICES EXTRAS
-- ============================================================
CREATE INDEX idx_aval_data_status     ON avaliacoes (realizada_em, status);
CREATE INDEX idx_paciente_nome_genero ON pacientes  (nome_completo, genero);
CREATE INDEX idx_audit_usuario_acao   ON audit_log  (usuario_id, acao);


-- ============================================================
--  VERIFICAÇÃO FINAL
-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;

SELECT '==============================='   AS '';
SELECT '  SXF CHECKLIST — DB CRIADO OK'    AS '';
SELECT '==============================='   AS '';

SELECT table_name AS tabela,
       table_rows AS linhas_aprox,
       ROUND((data_length + index_length) / 1024, 2) AS tamanho_kb
FROM   information_schema.tables
WHERE  table_schema = 'sxf_checklist'
ORDER  BY table_name;
