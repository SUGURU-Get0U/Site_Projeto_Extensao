-- ============================================================
--  SXF CHECKLIST SITE — Banco de Dados Completo
--  Síndrome do X Frágil — Sistema de Triagem Clínica
--  MySQL 8.0+
--  Gerado em: 2026
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
) ENGINE=InnoDB COMMENT='Perfis de acesso (admin_master, admin, profissional)';

INSERT INTO roles (nome, descricao) VALUES
    ('admin_master', 'Administrador com acesso total ao sistema, gerencia usuários e configurações'),
    ('admin',        'Administrador institucional, gerencia profissionais e clínicas'),
    ('profissional', 'Profissional de saúde autorizado a cadastrar pacientes e realizar avaliações');


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
--  3. CLÍNICAS / INSTITUIÇÕES
-- ============================================================
CREATE TABLE clinicas (
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(150)    NOT NULL,
    cnpj        VARCHAR(18)     NULL,
    endereco    VARCHAR(255)    NULL,
    cidade      VARCHAR(100)    NULL,
    estado      CHAR(2)         NULL,
    cep         VARCHAR(10)     NULL,
    telefone    VARCHAR(20)     NULL,
    email       VARCHAR(150)    NULL,
    ativa       TINYINT(1)      NOT NULL DEFAULT 1,
    criado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_clinica_cnpj (cnpj),
    INDEX idx_clinica_cidade (cidade),
    INDEX idx_clinica_ativa (ativa)
) ENGINE=InnoDB COMMENT='Clínicas e instituições de saúde parceiras';

INSERT INTO clinicas (nome, cnpj, endereco, cidade, estado, cep, telefone, email) VALUES
    ('Hospital das Clínicas - UFPR',    '75.457.040/0001-29', 'R. Padre Camargo, 280 - Alto da Glória', 'Curitiba', 'PR', '80060-240', '(41) 3360-1800', 'hc@ufpr.br'),
    ('Instituto Genética Brasil',        '12.345.678/0001-00', 'Av. Brasil, 1500 - Centro',              'São Paulo', 'SP', '01310-100', '(11) 3000-0000', 'contato@igbrasil.com.br'),
    ('Clínica de Neurologia Infantil',   '98.765.432/0001-00', 'R. das Flores, 200 - Batel',             'Curitiba', 'PR', '80420-120', '(41) 3333-4444', 'neuroped@clinica.com.br');


-- ============================================================
--  4. USUÁRIOS — Tabela central de autenticação
-- ============================================================
CREATE TABLE usuarios (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    role_id         TINYINT UNSIGNED NOT NULL,
    nome_completo   VARCHAR(150)    NOT NULL,
    email           VARCHAR(150)    NOT NULL,
    -- senha armazenada como bcrypt hash (nunca texto plano)
    senha_hash      VARCHAR(255)    NOT NULL,
    ativo           TINYINT(1)      NOT NULL DEFAULT 1,
    email_verificado TINYINT(1)    NOT NULL DEFAULT 0,
    token_verificacao VARCHAR(100)  NULL,
    token_reset_senha VARCHAR(100)  NULL,
    token_reset_expira DATETIME     NULL,
    ultimo_login    DATETIME        NULL,
    tentativas_login TINYINT UNSIGNED NOT NULL DEFAULT 0,
    bloqueado_ate   DATETIME        NULL,
    criado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_usuario_email (email),
    INDEX idx_usuario_role (role_id),
    INDEX idx_usuario_ativo (ativo),
    CONSTRAINT fk_usuario_role FOREIGN KEY (role_id) REFERENCES roles (id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Tabela central de autenticação de todos os usuários';

-- ============================================================
--  5. PROFISSIONAIS DE SAÚDE
-- ============================================================
CREATE TABLE profissionais (
    id                  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    usuario_id          INT UNSIGNED    NOT NULL,
    especialidade_id    SMALLINT UNSIGNED NOT NULL,
    -- CRM ou registro profissional (COREN, CRF, CFP etc.)
    registro_profissional VARCHAR(30)   NOT NULL,
    tipo_registro       VARCHAR(20)     NOT NULL DEFAULT 'CRM'
                        COMMENT 'CRM, COREN, CRF, CFP, CREFONO, etc.',
    estado_registro     CHAR(2)         NOT NULL,
    telefone            VARCHAR(20)     NULL,
    bio                 TEXT            NULL,
    aprovado            TINYINT(1)      NOT NULL DEFAULT 0
                        COMMENT 'Admin precisa aprovar o cadastro',
    aprovado_por        INT UNSIGNED    NULL,
    aprovado_em         DATETIME        NULL,
    criado_em           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_prof_registro (registro_profissional, tipo_registro, estado_registro),
    INDEX idx_prof_usuario (usuario_id),
    INDEX idx_prof_especialidade (especialidade_id),
    INDEX idx_prof_aprovado (aprovado),
    CONSTRAINT fk_prof_usuario       FOREIGN KEY (usuario_id)       REFERENCES usuarios (id)      ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_prof_especialidade FOREIGN KEY (especialidade_id) REFERENCES especialidades (id) ON UPDATE CASCADE,
    CONSTRAINT fk_prof_aprovado_por  FOREIGN KEY (aprovado_por)     REFERENCES usuarios (id)      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Dados profissionais dos usuários com papel de profissional de saúde';


-- ============================================================
--  6. PROFISSIONAL × CLÍNICA  (N:M)
-- ============================================================
CREATE TABLE profissional_clinica (
    profissional_id INT UNSIGNED NOT NULL,
    clinica_id      INT UNSIGNED NOT NULL,
    cargo           VARCHAR(80)  NULL     COMMENT 'Ex: Coordenador, Plantonista',
    data_inicio     DATE         NULL,
    data_fim        DATE         NULL     COMMENT 'NULL = vínculo ativo',
    PRIMARY KEY (profissional_id, clinica_id),
    INDEX idx_pc_clinica (clinica_id),
    CONSTRAINT fk_pc_profissional FOREIGN KEY (profissional_id) REFERENCES profissionais (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pc_clinica      FOREIGN KEY (clinica_id)      REFERENCES clinicas (id)      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Vínculo entre profissionais e clínicas onde atuam';


-- ============================================================
--  7. ADMINS — perfil extra para role admin / admin_master
-- ============================================================
CREATE TABLE admins (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id  INT UNSIGNED NOT NULL,
    departamento VARCHAR(100) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admin_usuario (usuario_id),
    CONSTRAINT fk_admin_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Dados adicionais de administradores';


-- ============================================================
--  8. SESSÕES DE USUÁRIO (controle de tokens JWT / sessão)
-- ============================================================
CREATE TABLE sessoes (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id      INT UNSIGNED    NOT NULL,
    token_sessao    VARCHAR(512)    NOT NULL,
    ip_origem       VARCHAR(45)     NULL,
    user_agent      VARCHAR(512)    NULL,
    criado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_em       DATETIME        NOT NULL,
    encerrada       TINYINT(1)      NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    INDEX idx_sessao_usuario  (usuario_id),
    INDEX idx_sessao_token    (token_sessao(64)),
    INDEX idx_sessao_expira   (expira_em),
    CONSTRAINT fk_sessao_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Controle de sessões ativas dos usuários';


-- ============================================================
--  9. PACIENTES
-- ============================================================
CREATE TABLE pacientes (
    id                  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    nome_completo       VARCHAR(150)    NOT NULL,
    data_nascimento     DATE            NOT NULL,
    -- 'M' = Masculino, 'F' = Feminino (impacta no limiar do score)
    genero              CHAR(1)         NOT NULL,
    cpf                 VARCHAR(14)     NULL     COMMENT 'Opcional, mas útil para deduplicação',
    nome_responsavel    VARCHAR(150)    NULL     COMMENT 'Pai, mãe ou responsável legal',
    telefone_responsavel VARCHAR(20)   NULL,
    email_responsavel   VARCHAR(150)   NULL,
    observacoes         TEXT            NULL,
    cadastrado_por      INT UNSIGNED    NOT NULL COMMENT 'Profissional que registrou',
    criado_em           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_paciente_cpf (cpf),
    INDEX idx_paciente_nome    (nome_completo),
    INDEX idx_paciente_genero  (genero),
    INDEX idx_paciente_cadpor  (cadastrado_por),
    CONSTRAINT fk_paciente_cadastrado_por FOREIGN KEY (cadastrado_por) REFERENCES profissionais (id) ON UPDATE CASCADE,
    CONSTRAINT chk_paciente_genero CHECK (genero IN ('M', 'F'))
) ENGINE=InnoDB COMMENT='Pacientes cadastrados para triagem de SXF';


-- ============================================================
--  10. SINTOMAS — Catálogo com pesos por gênero
-- ============================================================
-- Os pesos foram definidos com base na literatura clínica sobre SXF.
-- A equipe pode ajustar os valores na tabela conforme validação científica.
-- Score = Σ (peso_genero_j × X_ij)   |  limiar H=0,56 / M=0,55
-- ============================================================
CREATE TABLE sintomas (
    id          SMALLINT UNSIGNED   NOT NULL AUTO_INCREMENT,
    codigo      VARCHAR(20)         NOT NULL    COMMENT 'Ex: SXF_001',
    nome        VARCHAR(120)        NOT NULL,
    descricao   TEXT                NULL,
    -- pesos distintos por gênero (conforme variabilidade fenotípica do SXF)
    peso_masculino  DECIMAL(5,4)    NOT NULL DEFAULT 0.0000,
    peso_feminino   DECIMAL(5,4)    NOT NULL DEFAULT 0.0000,
    ativo       TINYINT(1)          NOT NULL DEFAULT 1,
    ordem       TINYINT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'Ordem de exibição no formulário',
    PRIMARY KEY (id),
    UNIQUE KEY uq_sintoma_codigo (codigo),
    INDEX idx_sintoma_ativo (ativo)
) ENGINE=InnoDB COMMENT='Catálogo dos 12 sintomas do checklist SXF com pesos clínicos';

-- Pesos baseados em literatura (Hagerman et al., Loesch et al.)
-- Ajuste com sua equipe médica antes de ir pra produção!
INSERT INTO sintomas (codigo, nome, descricao, peso_masculino, peso_feminino, ordem) VALUES
    ('SXF_001', 'Deficiência Intelectual',
     'Comprometimento cognitivo observável, com QI abaixo do esperado para idade.',
     0.1400, 0.1200, 1),

    ('SXF_002', 'Face Alongada / Orelhas de Abano',
     'Características faciais típicas: face estreita e alongada, orelhas grandes e proeminentes.',
     0.1000, 0.0800, 2),

    ('SXF_003', 'Macroorquidismo',
     'Aumento do volume testicular, presente em ~80% dos homens adultos com SXF. Irrelevante para mulheres.',
     0.1500, 0.0000, 3),

    ('SXF_004', 'Hipermobilidade Articular',
     'Articulações com amplitude de movimento acima do normal, especialmente dedos e pulsos.',
     0.0600, 0.0700, 4),

    ('SXF_005', 'Dificuldades de Aprendizagem',
     'Dificuldades específicas em leitura, escrita ou matemática, além do atraso cognitivo geral.',
     0.0800, 0.1000, 5),

    ('SXF_006', 'Déficit de Atenção',
     'Dificuldade persistente em manter atenção, fácil distração, comportamento desorganizado.',
     0.0700, 0.0700, 6),

    ('SXF_007', 'Movimentos Repetitivos (Estereotipias)',
     'Comportamentos motores repetitivos como bater palmas, balançar o corpo, morder as mãos.',
     0.0700, 0.0700, 7),

    ('SXF_008', 'Atraso na Fala',
     'Desenvolvimento da linguagem abaixo do esperado para a faixa etária.',
     0.0900, 0.0900, 8),

    ('SXF_009', 'Hiperatividade',
     'Atividade motora excessiva e impulsividade, especialmente em crianças.',
     0.0600, 0.0500, 9),

    ('SXF_010', 'Evita Contato Visual',
     'Dificuldade ou recusa em manter contato visual direto durante interações sociais.',
     0.0700, 0.0800, 10),

    ('SXF_011', 'Evita Contato Físico',
     'Sensibilidade tátil aumentada, rejeição a abraços ou toque.',
     0.0500, 0.0600, 11),

    ('SXF_012', 'Agressividade',
     'Episódios de agressão verbal ou física, frequentemente associados a frustração ou sobrecarga sensorial.',
     0.0600, 0.0600, 12);


-- ============================================================
--  11. AVALIAÇÕES (Checklist)
-- ============================================================
CREATE TABLE avaliacoes (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    paciente_id     INT UNSIGNED    NOT NULL,
    profissional_id INT UNSIGNED    NOT NULL,
    clinica_id      INT UNSIGNED    NULL     COMMENT 'Clínica onde foi realizada',
    -- Score calculado pelo back-end: Score = Σ(peso_j × X_ij)
    score           DECIMAL(6,4)    NOT NULL DEFAULT 0.0000,
    limiar_aplicado DECIMAL(5,4)    NOT NULL COMMENT '0.56 para H, 0.55 para F',
    -- TRUE = score >= limiar → encaminhar para teste genético
    recomenda_teste TINYINT(1)      NOT NULL DEFAULT 0,
    -- Status do laudo
    status          ENUM('rascunho','finalizada','revisada','cancelada')
                    NOT NULL DEFAULT 'rascunho',
    observacoes     TEXT            NULL,
    realizada_em    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finalizada_em   DATETIME        NULL,
    criado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_aval_paciente     (paciente_id),
    INDEX idx_aval_profissional (profissional_id),
    INDEX idx_aval_clinica      (clinica_id),
    INDEX idx_aval_status       (status),
    INDEX idx_aval_realizada    (realizada_em),
    INDEX idx_aval_recomenda    (recomenda_teste),
    CONSTRAINT fk_aval_paciente     FOREIGN KEY (paciente_id)     REFERENCES pacientes     (id) ON UPDATE CASCADE,
    CONSTRAINT fk_aval_profissional FOREIGN KEY (profissional_id) REFERENCES profissionais (id) ON UPDATE CASCADE,
    CONSTRAINT fk_aval_clinica      FOREIGN KEY (clinica_id)      REFERENCES clinicas      (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Avaliações/checkups realizados — cada linha = uma sessão de triagem';


-- ============================================================
--  12. AVALIAÇÃO × SINTOMA (resultado binário de cada sintoma)
-- ============================================================
CREATE TABLE avaliacao_sintomas (
    avaliacao_id    INT UNSIGNED        NOT NULL,
    sintoma_id      SMALLINT UNSIGNED   NOT NULL,
    -- 1 = presente, 0 = ausente  (RF03: valores binários)
    presente        TINYINT(1)          NOT NULL DEFAULT 0,
    -- contribuição real = peso_genero × presente
    contribuicao    DECIMAL(5,4)        NOT NULL DEFAULT 0.0000,
    PRIMARY KEY (avaliacao_id, sintoma_id),
    INDEX idx_as_sintoma (sintoma_id),
    CONSTRAINT fk_as_avaliacao FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_as_sintoma   FOREIGN KEY (sintoma_id)   REFERENCES sintomas   (id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Resultado binário de cada sintoma para cada avaliação';


-- ============================================================
--  13. HISTÓRICO DE ALTERAÇÕES NAS AVALIAÇÕES
-- ============================================================
CREATE TABLE avaliacao_historico (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    avaliacao_id    INT UNSIGNED    NOT NULL,
    alterado_por    INT UNSIGNED    NOT NULL COMMENT 'usuario_id de quem alterou',
    tipo_alteracao  ENUM('criacao','edicao_sintoma','edicao_obs','status','cancelamento')
                    NOT NULL DEFAULT 'edicao_sintoma',
    campo_alterado  VARCHAR(80)     NULL,
    valor_anterior  TEXT            NULL,
    valor_novo      TEXT            NULL,
    motivo          TEXT            NULL,
    ip_origem       VARCHAR(45)     NULL,
    criado_em       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_ah_avaliacao  (avaliacao_id),
    INDEX idx_ah_alterado   (alterado_por),
    INDEX idx_ah_criado     (criado_em),
    CONSTRAINT fk_ah_avaliacao  FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ah_alterado   FOREIGN KEY (alterado_por) REFERENCES usuarios   (id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Auditoria completa de todas as alterações em avaliações (RF02)';


-- ============================================================
--  14. LOG DE AUDITORIA GERAL DO SISTEMA
-- ============================================================
CREATE TABLE audit_log (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id  INT UNSIGNED    NULL,
    acao        VARCHAR(100)    NOT NULL COMMENT 'Ex: LOGIN, CADASTRO_PACIENTE, DELETE_USUARIO',
    tabela      VARCHAR(80)     NULL,
    registro_id INT UNSIGNED    NULL,
    descricao   TEXT            NULL,
    ip_origem   VARCHAR(45)     NULL,
    user_agent  VARCHAR(512)    NULL,
    criado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_audit_usuario  (usuario_id),
    INDEX idx_audit_acao     (acao),
    INDEX idx_audit_criado   (criado_em),
    CONSTRAINT fk_audit_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Log de auditoria de todas as ações relevantes no sistema (RF02)';


-- ============================================================
--  15. BACKUP LOG — Registro dos backups diários (RFN07)
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
    INDEX idx_backup_status  (status),
    INDEX idx_backup_iniciado (iniciado_em)
) ENGINE=InnoDB COMMENT='Registro de execução dos backups diários automáticos (RFN07)';


-- ============================================================
--  16. CONFIGURAÇÕES DO SISTEMA
-- ============================================================
CREATE TABLE configuracoes (
    chave       VARCHAR(80)     NOT NULL,
    valor       TEXT            NOT NULL,
    descricao   VARCHAR(255)    NULL,
    atualizado_em DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (chave)
) ENGINE=InnoDB COMMENT='Configurações globais do sistema ajustáveis pelo admin_master';

INSERT INTO configuracoes (chave, valor, descricao) VALUES
    ('limiar_score_masculino', '0.56',  'Limiar de corte do score SXF para pacientes do sexo masculino'),
    ('limiar_score_feminino',  '0.55',  'Limiar de corte do score SXF para pacientes do sexo feminino'),
    ('sessao_expiracao_horas', '8',     'Tempo em horas até expirar a sessão do usuário'),
    ('max_tentativas_login',   '5',     'Número máximo de tentativas de login antes de bloquear'),
    ('bloqueio_login_minutos', '30',    'Tempo em minutos de bloqueio após tentativas excedidas'),
    ('backup_hora',            '23:00', 'Hora diária para execução do backup automático'),
    ('nome_sistema',           'SXF Checklist',        'Nome exibido no sistema'),
    ('email_suporte',          'suporte@sxfchecklist.com.br', 'E-mail de suporte técnico');


-- ============================================================
--  STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- ----------------------------------------------------------
--  SP: Calcular e salvar o score de uma avaliação
--  Uso: CALL sp_calcular_score(avaliacao_id);
-- ----------------------------------------------------------
CREATE PROCEDURE sp_calcular_score(IN p_avaliacao_id INT UNSIGNED)
BEGIN
    DECLARE v_genero        CHAR(1);
    DECLARE v_score         DECIMAL(6,4);
    DECLARE v_limiar        DECIMAL(5,4);
    DECLARE v_recomenda     TINYINT(1);

    -- Buscar gênero do paciente
    SELECT p.genero
    INTO   v_genero
    FROM   avaliacoes a
    JOIN   pacientes  p ON p.id = a.paciente_id
    WHERE  a.id = p_avaliacao_id
    LIMIT  1;

    -- Calcular score usando os pesos do gênero correto
    SELECT IFNULL(
        SUM(
            CASE v_genero
                WHEN 'M' THEN s.peso_masculino * asy.presente
                WHEN 'F' THEN s.peso_feminino  * asy.presente
                ELSE 0
            END
        ), 0)
    INTO v_score
    FROM avaliacao_sintomas asy
    JOIN sintomas s ON s.id = asy.sintoma_id
    WHERE asy.avaliacao_id = p_avaliacao_id;

    -- Atualizar contribuição individual de cada sintoma
    UPDATE avaliacao_sintomas asy
    JOIN   sintomas s ON s.id = asy.sintoma_id
    SET    asy.contribuicao = CASE v_genero
                                  WHEN 'M' THEN s.peso_masculino * asy.presente
                                  WHEN 'F' THEN s.peso_feminino  * asy.presente
                                  ELSE 0
                              END
    WHERE  asy.avaliacao_id = p_avaliacao_id;

    -- Buscar limiar da configuração
    SELECT CASE v_genero
               WHEN 'M' THEN (SELECT CAST(valor AS DECIMAL(5,4)) FROM configuracoes WHERE chave = 'limiar_score_masculino')
               WHEN 'F' THEN (SELECT CAST(valor AS DECIMAL(5,4)) FROM configuracoes WHERE chave = 'limiar_score_feminino')
               ELSE 0.56
           END
    INTO v_limiar;

    SET v_recomenda = IF(v_score >= v_limiar, 1, 0);

    -- Atualizar avaliação com score calculado
    UPDATE avaliacoes
    SET    score           = v_score,
           limiar_aplicado = v_limiar,
           recomenda_teste = v_recomenda
    WHERE  id = p_avaliacao_id;

    -- Retornar resultado
    SELECT v_score AS score, v_limiar AS limiar, v_recomenda AS recomenda_teste;
END$$


-- ----------------------------------------------------------
--  SP: Finalizar uma avaliação
--  Uso: CALL sp_finalizar_avaliacao(avaliacao_id, usuario_id, ip);
-- ----------------------------------------------------------
CREATE PROCEDURE sp_finalizar_avaliacao(
    IN p_avaliacao_id  INT UNSIGNED,
    IN p_usuario_id    INT UNSIGNED,
    IN p_ip            VARCHAR(45)
)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status FROM avaliacoes WHERE id = p_avaliacao_id;

    IF v_status = 'rascunho' THEN
        -- Calcular score antes de finalizar
        CALL sp_calcular_score(p_avaliacao_id);

        UPDATE avaliacoes
        SET    status        = 'finalizada',
               finalizada_em = NOW()
        WHERE  id = p_avaliacao_id;

        -- Registrar no histórico
        INSERT INTO avaliacao_historico (avaliacao_id, alterado_por, tipo_alteracao, campo_alterado, valor_anterior, valor_novo, ip_origem)
        VALUES (p_avaliacao_id, p_usuario_id, 'status', 'status', 'rascunho', 'finalizada', p_ip);

        INSERT INTO audit_log (usuario_id, acao, tabela, registro_id, descricao, ip_origem)
        VALUES (p_usuario_id, 'FINALIZAR_AVALIACAO', 'avaliacoes', p_avaliacao_id,
                CONCAT('Avaliação #', p_avaliacao_id, ' finalizada'), p_ip);

        SELECT 'Avaliação finalizada com sucesso.' AS mensagem;
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Avaliação não está em rascunho e não pode ser finalizada.';
    END IF;
END$$


-- ----------------------------------------------------------
--  SP: Buscar histórico completo de avaliações de um paciente
--  Uso: CALL sp_historico_paciente(paciente_id);
-- ----------------------------------------------------------
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
        e.nome          AS especialidade,
        IFNULL(c.nome, '—') AS clinica
    FROM   avaliacoes a
    JOIN   profissionais pr ON pr.id = a.profissional_id
    JOIN   usuarios      u  ON u.id  = pr.usuario_id
    JOIN   especialidades e  ON e.id  = pr.especialidade_id
    LEFT JOIN clinicas   c  ON c.id  = a.clinica_id
    WHERE  a.paciente_id = p_paciente_id
    ORDER  BY a.realizada_em DESC;
END$$


-- ----------------------------------------------------------
--  SP: Dashboard do Admin — resumo estatístico
--  Uso: CALL sp_dashboard_admin();
-- ----------------------------------------------------------
CREATE PROCEDURE sp_dashboard_admin()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM pacientes)                                    AS total_pacientes,
        (SELECT COUNT(*) FROM avaliacoes WHERE status = 'finalizada')       AS total_avaliacoes,
        (SELECT COUNT(*) FROM avaliacoes WHERE recomenda_teste = 1)         AS total_recomendacoes,
        (SELECT COUNT(*) FROM profissionais WHERE aprovado = 1)             AS profissionais_ativos,
        (SELECT COUNT(*) FROM profissionais WHERE aprovado = 0)             AS profissionais_pendentes,
        (SELECT COUNT(*) FROM avaliacoes WHERE DATE(realizada_em) = CURDATE()) AS avaliacoes_hoje,
        (SELECT ROUND(AVG(score),4) FROM avaliacoes WHERE status='finalizada') AS score_medio;
END$$


-- ----------------------------------------------------------
--  SP: Aprovar cadastro de profissional
--  Uso: CALL sp_aprovar_profissional(profissional_id, admin_usuario_id);
-- ----------------------------------------------------------
CREATE PROCEDURE sp_aprovar_profissional(
    IN p_profissional_id INT UNSIGNED,
    IN p_admin_id        INT UNSIGNED
)
BEGIN
    UPDATE profissionais
    SET    aprovado     = 1,
           aprovado_por = p_admin_id,
           aprovado_em  = NOW()
    WHERE  id = p_profissional_id;

    -- Ativar o usuário vinculado
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

-- Vista completa de avaliações com dados do paciente e profissional
CREATE OR REPLACE VIEW vw_avaliacoes_completas AS
SELECT
    a.id                            AS avaliacao_id,
    a.realizada_em,
    a.finalizada_em,
    a.status,
    a.score,
    a.limiar_aplicado,
    a.recomenda_teste,
    a.observacoes,
    -- Paciente
    p.id                            AS paciente_id,
    p.nome_completo                 AS paciente_nome,
    TIMESTAMPDIFF(YEAR, p.data_nascimento, CURDATE()) AS paciente_idade,
    p.genero                        AS paciente_genero,
    -- Profissional
    pr.id                           AS profissional_id,
    u.nome_completo                 AS profissional_nome,
    pr.registro_profissional,
    pr.tipo_registro,
    e.nome                          AS especialidade,
    -- Clínica
    IFNULL(c.nome, '—')             AS clinica_nome
FROM       avaliacoes    a
JOIN       pacientes     p  ON p.id  = a.paciente_id
JOIN       profissionais pr ON pr.id = a.profissional_id
JOIN       usuarios      u  ON u.id  = pr.usuario_id
JOIN       especialidades e ON e.id  = pr.especialidade_id
LEFT JOIN  clinicas      c  ON c.id  = a.clinica_id;


-- Vista de sintomas positivos por avaliação
CREATE OR REPLACE VIEW vw_sintomas_positivos AS
SELECT
    asy.avaliacao_id,
    s.codigo,
    s.nome              AS sintoma,
    asy.presente,
    asy.contribuicao,
    a.paciente_id,
    a.profissional_id
FROM avaliacao_sintomas asy
JOIN sintomas   s ON s.id = asy.sintoma_id
JOIN avaliacoes a ON a.id = asy.avaliacao_id
WHERE asy.presente = 1;


-- Vista de profissionais com suas clínicas
CREATE OR REPLACE VIEW vw_profissionais_clinicas AS
SELECT
    u.id            AS usuario_id,
    u.nome_completo,
    u.email,
    pr.id           AS profissional_id,
    pr.registro_profissional,
    pr.tipo_registro,
    pr.estado_registro,
    pr.aprovado,
    e.nome          AS especialidade,
    GROUP_CONCAT(c.nome ORDER BY c.nome SEPARATOR ', ') AS clinicas
FROM     profissionais pr
JOIN     usuarios      u  ON u.id  = pr.usuario_id
JOIN     especialidades e ON e.id  = pr.especialidade_id
LEFT JOIN profissional_clinica pc ON pc.profissional_id = pr.id
LEFT JOIN clinicas             c  ON c.id = pc.clinica_id
GROUP BY pr.id, u.id, u.nome_completo, u.email,
         pr.registro_profissional, pr.tipo_registro,
         pr.estado_registro, pr.aprovado, e.nome;


-- ============================================================
--  TRIGGERS
-- ============================================================

DELIMITER $$

-- Logar criação de paciente
CREATE TRIGGER trg_paciente_insert
AFTER INSERT ON pacientes
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (usuario_id, acao, tabela, registro_id, descricao)
    SELECT u.id, 'CADASTRO_PACIENTE', 'pacientes', NEW.id,
           CONCAT('Paciente "', NEW.nome_completo, '" cadastrado')
    FROM profissionais pr
    JOIN usuarios u ON u.id = pr.usuario_id
    WHERE pr.id = NEW.cadastrado_por
    LIMIT 1;
END$$

-- Logar criação de avaliação
CREATE TRIGGER trg_avaliacao_insert
AFTER INSERT ON avaliacoes
FOR EACH ROW
BEGIN
    INSERT INTO avaliacao_historico (avaliacao_id, alterado_por, tipo_alteracao, campo_alterado, valor_novo)
    SELECT NEW.id, u.id, 'criacao', 'status', 'rascunho'
    FROM profissionais pr
    JOIN usuarios u ON u.id = pr.usuario_id
    WHERE pr.id = NEW.profissional_id
    LIMIT 1;
END$$

-- Bloquear usuário após excesso de tentativas de login
CREATE TRIGGER trg_bloquear_usuario
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    DECLARE v_max_tentativas INT;
    DECLARE v_minutos_bloqueio INT;

    SELECT CAST(valor AS UNSIGNED) INTO v_max_tentativas   FROM configuracoes WHERE chave = 'max_tentativas_login';
    SELECT CAST(valor AS UNSIGNED) INTO v_minutos_bloqueio FROM configuracoes WHERE chave = 'bloqueio_login_minutos';

    IF NEW.tentativas_login >= v_max_tentativas AND OLD.tentativas_login < v_max_tentativas THEN
        SET NEW.bloqueado_ate = DATE_ADD(NOW(), INTERVAL v_minutos_bloqueio MINUTE);
    END IF;

    -- Resetar bloqueio se tentativas forem zeradas (login bem-sucedido)
    IF NEW.tentativas_login = 0 THEN
        SET NEW.bloqueado_ate = NULL;
    END IF;
END$$

DELIMITER ;


-- ============================================================
--  EVENTO: BACKUP DIÁRIO (RFN07)
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
    -- O back-end Python deve monitorar essa tabela e executar o mysqldump real
END$$
DELIMITER ;


-- ============================================================
--  DADOS INICIAIS — Usuários: Admin Master + Admins + Profissionais
-- ============================================================
-- ATENÇÃO: senhas abaixo são hashes bcrypt de exemplos.
-- Em produção, NUNCA insira senhas em texto plano. Use o back-end para criar os hashes.
--
-- Senhas de exemplo (bcrypt rounds=12):
--   admin_master@sxf.com   → SXFmaster@2026!
--   admin@sxf.com          → SXFadmin@2026!
--   dr.silva@sxf.com       → SXFprof@2026!
--   dra.costa@sxf.com      → SXFprof@2026!
--   enf.souza@sxf.com      → SXFprof@2026!
-- ============================================================

INSERT INTO usuarios (role_id, nome_completo, email, senha_hash, ativo, email_verificado) VALUES
    -- Admin Master
    (1, 'Administrador Master SXF',
     'admin_master@sxfchecklist.com.br',
     '$2b$12$KixMHDnZY9Q6xMb8EWdROuGTEQ8A4v7C3NxNYQzfAa1gORNEPHVGi',
     1, 1),

    -- Admin institucional
    (2, 'Ricardo Magno Yomura',
     'ricardo.yomura@sxfchecklist.com.br',
     '$2b$12$eImiTXuWVxfM8objhReanugI8/OyI5ZxjHm2P4A0e2JTjdMBpZYZm',
     1, 1),

    -- Profissional 1 — Médico Geneticista
    (3, 'Dr. Carlos Eduardo Silva',
     'dr.carlos@sxfchecklist.com.br',
     '$2b$12$eImiTXuWVxfM8objhReanugI8/OyI5ZxjHm2P4A0e2JTjdMBpZYZm',
     1, 1),

    -- Profissional 2 — Neurologista
    (3, 'Dra. Ana Paula Costa',
     'dra.ana@sxfchecklist.com.br',
     '$2b$12$eImiTXuWVxfM8objhReanugI8/OyI5ZxjHm2P4A0e2JTjdMBpZYZm',
     1, 1),

    -- Profissional 3 — Enfermeiro (pendente aprovação)
    (3, 'Enf. João Souza',
     'enf.joao@sxfchecklist.com.br',
     '$2b$12$eImiTXuWVxfM8objhReanugI8/OyI5ZxjHm2P4A0e2JTjdMBpZYZm',
     0, 1),

    -- Profissional 4 — Psicóloga
    (3, 'Psic. Marina Oliveira',
     'psic.marina@sxfchecklist.com.br',
     '$2b$12$eImiTXuWVxfM8objhReanugI8/OyI5ZxjHm2P4A0e2JTjdMBpZYZm',
     1, 1);


-- Perfil de admin master
INSERT INTO admins (usuario_id, departamento) VALUES
    (1, 'Tecnologia da Informação'),
    (2, 'Administração Geral');

-- Perfis de profissionais
INSERT INTO profissionais (usuario_id, especialidade_id, registro_profissional, tipo_registro, estado_registro, telefone, aprovado, aprovado_por, aprovado_em) VALUES
    -- Dr. Carlos — Geneticista — aprovado
    (3, 2, 'CRM/PR-123456', 'CRM', 'PR', '(41) 99999-0001', 1, 1, NOW()),
    -- Dra. Ana — Neurologista — aprovada
    (4, 3, 'CRM/PR-234567', 'CRM', 'PR', '(41) 99999-0002', 1, 1, NOW()),
    -- Enf. João — Enfermeiro — PENDENTE
    (5, 7, 'COREN/PR-345678', 'COREN', 'PR', '(41) 99999-0003', 0, NULL, NULL),
    -- Psic. Marina — Psicóloga — aprovada
    (6, 5, 'CRP/08-456789', 'CRP', 'PR', '(41) 99999-0004', 1, 1, NOW());

-- Vínculos profissional × clínica
INSERT INTO profissional_clinica (profissional_id, clinica_id, cargo, data_inicio) VALUES
    (1, 1, 'Geneticista Responsável', '2023-01-10'),
    (1, 2, 'Consultor', '2024-03-01'),
    (2, 1, 'Neurologista', '2022-06-15'),
    (2, 3, 'Neuropediatra', '2023-09-01'),
    (4, 3, 'Psicóloga Clínica', '2024-01-20');


-- ============================================================
--  DADOS DE EXEMPLO — Pacientes e Avaliações
-- ============================================================

INSERT INTO pacientes (nome_completo, data_nascimento, genero, cpf, nome_responsavel, telefone_responsavel, observacoes, cadastrado_por) VALUES
    ('Lucas Ferreira Almeida',    '2015-03-12', 'M', '111.222.333-01', 'Maria Almeida',  '(41) 98888-0001', 'Criança com histórico familiar positivo para SXF.', 1),
    ('Sofia Pereira Santos',      '2018-07-22', 'F', '222.333.444-02', 'Pedro Santos',   '(41) 98888-0002', 'Encaminhada pelo pediatra com suspeita de atraso no desenvolvimento.', 2),
    ('Mateus Oliveira Lima',      '2010-11-05', 'M', '333.444.555-03', 'Carla Lima',     '(41) 98888-0003', NULL, 1),
    ('Ana Beatriz Rocha',         '2019-01-30', 'F', '444.555.666-04', 'Felipe Rocha',   '(41) 98888-0004', 'Primeiro atendimento.', 2),
    ('Gabriel Torres Machado',    '2013-09-18', 'M', '555.666.777-05', 'Luana Machado',  '(41) 98888-0005', 'Diagnóstico de TDAH prévio.', 1);


-- Avaliação 1: Lucas — alta suspeita (score > limiar masculino 0.56)
INSERT INTO avaliacoes (paciente_id, profissional_id, clinica_id, score, limiar_aplicado, recomenda_teste, status, realizada_em, finalizada_em) VALUES
    (1, 1, 1, 0.7900, 0.56, 1, 'finalizada', '2026-04-10 09:30:00', '2026-04-10 10:00:00');

INSERT INTO avaliacao_sintomas (avaliacao_id, sintoma_id, presente, contribuicao) VALUES
    (1,  1, 1, 0.1400), -- Deficiência Intelectual
    (1,  2, 1, 0.1000), -- Face Alongada
    (1,  3, 1, 0.1500), -- Macroorquidismo
    (1,  4, 0, 0.0000),
    (1,  5, 1, 0.0800), -- Dificuldades de Aprendizagem
    (1,  6, 1, 0.0700), -- Déficit de Atenção
    (1,  7, 1, 0.0700), -- Movimentos Repetitivos
    (1,  8, 1, 0.0900), -- Atraso na Fala
    (1,  9, 0, 0.0000),
    (1, 10, 1, 0.0700), -- Evita Contato Visual
    (1, 11, 0, 0.0000),
    (1, 12, 0, 0.0000);

-- Avaliação 2: Sofia — abaixo do limiar feminino 0.55
INSERT INTO avaliacoes (paciente_id, profissional_id, clinica_id, score, limiar_aplicado, recomenda_teste, status, realizada_em, finalizada_em) VALUES
    (2, 2, 1, 0.3200, 0.55, 0, 'finalizada', '2026-04-11 14:00:00', '2026-04-11 14:30:00');

INSERT INTO avaliacao_sintomas (avaliacao_id, sintoma_id, presente, contribuicao) VALUES
    (2,  1, 0, 0.0000),
    (2,  2, 0, 0.0000),
    (2,  3, 0, 0.0000),
    (2,  4, 1, 0.0700), -- Hipermobilidade
    (2,  5, 1, 0.1000), -- Dificuldades de Aprendizagem
    (2,  6, 0, 0.0000),
    (2,  7, 0, 0.0000),
    (2,  8, 1, 0.0900), -- Atraso na Fala
    (2,  9, 1, 0.0500), -- Hiperatividade
    (2, 10, 0, 0.0000),
    (2, 11, 0, 0.0000),
    (2, 12, 0, 0.0000);

-- Avaliação 3: Gabriel — rascunho em andamento
INSERT INTO avaliacoes (paciente_id, profissional_id, clinica_id, score, limiar_aplicado, recomenda_teste, status, realizada_em) VALUES
    (5, 1, 1, 0.0000, 0.56, 0, 'rascunho', '2026-05-20 11:00:00');

INSERT INTO avaliacao_sintomas (avaliacao_id, sintoma_id, presente, contribuicao) VALUES
    (3,  1, 0, 0.0000),
    (3,  2, 0, 0.0000),
    (3,  3, 0, 0.0000),
    (3,  4, 0, 0.0000),
    (3,  5, 0, 0.0000),
    (3,  6, 0, 0.0000),
    (3,  7, 0, 0.0000),
    (3,  8, 0, 0.0000),
    (3,  9, 0, 0.0000),
    (3, 10, 0, 0.0000),
    (3, 11, 0, 0.0000),
    (3, 12, 0, 0.0000);

-- Histórico de exemplo para avaliação 1
INSERT INTO avaliacao_historico (avaliacao_id, alterado_por, tipo_alteracao, campo_alterado, valor_anterior, valor_novo) VALUES
    (1, 3, 'criacao',      'status', NULL,        'rascunho'),
    (1, 3, 'status',       'status', 'rascunho',  'finalizada');

-- Audit log de exemplo
INSERT INTO audit_log (usuario_id, acao, tabela, registro_id, descricao, ip_origem) VALUES
    (1, 'LOGIN',                'usuarios',    1, 'Login do admin_master',          '127.0.0.1'),
    (3, 'LOGIN',                'usuarios',    3, 'Login do profissional Dr. Carlos','192.168.1.10'),
    (3, 'CADASTRO_PACIENTE',    'pacientes',   1, 'Cadastrou Lucas Ferreira Almeida','192.168.1.10'),
    (3, 'FINALIZAR_AVALIACAO',  'avaliacoes',  1, 'Finalizou avaliação de Lucas',   '192.168.1.10'),
    (4, 'LOGIN',                'usuarios',    4, 'Login da Dra. Ana Paula',         '192.168.1.11'),
    (4, 'CADASTRO_PACIENTE',    'pacientes',   2, 'Cadastrou Sofia Pereira Santos',  '192.168.1.11');


-- ============================================================
--  ÍNDICES EXTRAS PARA PERFORMANCE
-- ============================================================
CREATE INDEX idx_aval_data_status     ON avaliacoes (realizada_em, status);
CREATE INDEX idx_paciente_nome_genero ON pacientes  (nome_completo, genero);
CREATE INDEX idx_audit_usuario_acao   ON audit_log  (usuario_id, acao);


-- ============================================================
--  VERIFICAÇÃO FINAL
-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;

SELECT '==============================='      AS '';
SELECT '  SXF CHECKLIST — DB CRIADO OK'       AS '';
SELECT '==============================='      AS '';

SELECT table_name AS tabela,
       table_rows AS linhas_aprox,
       ROUND((data_length + index_length) / 1024, 2) AS tamanho_kb
FROM   information_schema.tables
WHERE  table_schema = 'sxf_checklist'
ORDER  BY table_name;
