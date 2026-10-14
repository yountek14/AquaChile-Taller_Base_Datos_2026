/* ============================================================
 PROYECTO: AUTOMATIZACIÓN DEL PROCESO DE EVALUACIÓN PSICOLABORAL - AquaChile

 LIMPIEZA DEL ESQUEMA
 ============================================================ */
BEGIN
 FOR T IN (
 SELECT TABLE_NAME
 FROM USER_TABLES
 WHERE TABLE_NAME IN (
 'AUDITORIA_ESTADO',
 'AUDITORIA_CARGA_DOCUMENTOS',
 'INFORMEPSICOLABORAL',
 'ENTREVISTA',
 'DOCUMENTO',
 'SOLICITUDEVALUACION',
 'CARGO',
 'FAMILIACARGO',
 'CANDIDATO',
 'PSICOLOGO',
 'ANALISTA'
 )
 ) LOOP
 EXECUTE IMMEDIATE
 'DROP TABLE ' || T.TABLE_NAME || ' CASCADE CONSTRAINTS PURGE';
 END LOOP;
END;
/

/* ============================================================
 ANALISTA
 ============================================================ */
CREATE TABLE ANALISTA (
 analista_id NUMBER GENERATED ALWAYS AS IDENTITY,
 nombre VARCHAR2(100) NOT NULL,
 correo VARCHAR2(150) NOT NULL,
 CONSTRAINT pk_analista
 PRIMARY KEY (analista_id),
 CONSTRAINT uk_analista_correo
 UNIQUE (correo)
);

/* ============================================================
 PSICOLOGO
 ============================================================ */
CREATE TABLE PSICOLOGO (
 psicologo_id NUMBER GENERATED ALWAYS AS IDENTITY,
 nombre VARCHAR2(100) NOT NULL,
 correo VARCHAR2(150) NOT NULL,
 CONSTRAINT pk_psicologo
 PRIMARY KEY (psicologo_id),
 CONSTRAINT uk_psicologo_correo
 UNIQUE (correo)
);

/* ============================================================
 CANDIDATO
 El CV se maneja como DOCUMENTO para evitar redundancia.
 ============================================================ */
CREATE TABLE CANDIDATO (
 candidato_id NUMBER GENERATED ALWAYS AS IDENTITY,
 nombre VARCHAR2(100) NOT NULL,
 CONSTRAINT pk_candidato
 PRIMARY KEY (candidato_id)
);

/* ============================================================
 FAMILIA CARGO
 ============================================================ */
CREATE TABLE FAMILIACARGO (
 familiacargo_id NUMBER GENERATED ALWAYS AS IDENTITY,
 nombre_familia VARCHAR2(100) NOT NULL,
 descripcion VARCHAR2(255),
 CONSTRAINT pk_familiacargo
 PRIMARY KEY (familiacargo_id),
 CONSTRAINT uk_familiacargo_nombre
 UNIQUE (nombre_familia)
);

/* ============================================================
 CARGO
 Un cargo pertenece a una familia de cargo.
 ============================================================ */
CREATE TABLE CARGO (
 cargo_id NUMBER GENERATED ALWAYS AS IDENTITY,
 nombre_cargo VARCHAR2(100) NOT NULL,
 familiacargo_id NUMBER NOT NULL,
 CONSTRAINT pk_cargo
 PRIMARY KEY (cargo_id),
 CONSTRAINT fk_cargo_familiacargo
 FOREIGN KEY (familiacargo_id)
 REFERENCES FAMILIACARGO (familiacargo_id),
 CONSTRAINT uk_cargo_nombre
 UNIQUE (nombre_cargo)
);

/* ============================================================
 SOLICITUD DE EVALUACION
 Una solicitud identifica al candidato, cargo y analista.
 El psicólogo se registra en ENTREVISTA, evitando duplicidad.
 ============================================================ */
CREATE TABLE SOLICITUDEVALUACION (
 solicitud_id VARCHAR2(20),
 fecha_solicitud DATE NOT NULL,
 estado VARCHAR2(30) NOT NULL,
 candidato_id NUMBER NOT NULL,
 cargo_id NUMBER NOT NULL,
 analista_id NUMBER NOT NULL,
 CONSTRAINT pk_solicitud
 PRIMARY KEY (solicitud_id),
 CONSTRAINT fk_solicitud_candidato
 FOREIGN KEY (candidato_id)
 REFERENCES CANDIDATO (candidato_id),
 CONSTRAINT fk_solicitud_cargo
 FOREIGN KEY (cargo_id)
 REFERENCES CARGO (cargo_id),
 CONSTRAINT fk_solicitud_analista
 FOREIGN KEY (analista_id)
 REFERENCES ANALISTA (analista_id),
 CONSTRAINT ck_solicitud_estado
 CHECK (
 estado IN (
 'PENDIENTE',
 'EN_EVALUACION',
 'COMPLETADA',
 'CANCELADA'
 )
 )
);

/* ============================================================
 DOCUMENTO
 Una solicitud puede tener múltiples documentos:
 CV, pauta, transcripción, informe, etc.
 ============================================================ */
CREATE TABLE DOCUMENTO (
 documento_id NUMBER GENERATED ALWAYS AS IDENTITY,
 tipo_doc VARCHAR2(50) NOT NULL,
 fecha_creacion DATE NOT NULL,
 solicitud_id VARCHAR2(20) NOT NULL,
 CONSTRAINT pk_documento
 PRIMARY KEY (documento_id),
 CONSTRAINT fk_documento_solicitud
 FOREIGN KEY (solicitud_id)
 REFERENCES SOLICITUDEVALUACION (solicitud_id)
);

/* ============================================================
 ENTREVISTA
 Una solicitud puede tener cero o una entrevista.
 Una entrevista pertenece a un psicólogo.
 ============================================================ */
CREATE TABLE ENTREVISTA (
 entrevista_id NUMBER GENERATED ALWAYS AS IDENTITY,
 fecha_entrevista DATE NOT NULL,
 observaciones VARCHAR2(500),
 transcripcion VARCHAR2(4000),
 solicitud_id VARCHAR2(20) NOT NULL,
 psicologo_id NUMBER NOT NULL,
 CONSTRAINT pk_entrevista
 PRIMARY KEY (entrevista_id),
 CONSTRAINT fk_entrevista_solicitud
 FOREIGN KEY (solicitud_id)
 REFERENCES SOLICITUDEVALUACION (solicitud_id),
 CONSTRAINT fk_entrevista_psicologo
 FOREIGN KEY (psicologo_id)
 REFERENCES PSICOLOGO (psicologo_id),
 CONSTRAINT uk_entrevista_solicitud
 UNIQUE (solicitud_id)
);

/* ============================================================
 INFORME PSICOLABORAL
 Una entrevista puede generar cero o un informe.
 ============================================================ */
CREATE TABLE INFORMEPSICOLABORAL (
 informe_id NUMBER GENERATED ALWAYS AS IDENTITY,
 fecha_generacion DATE NOT NULL,
 contenido VARCHAR2(4000),
 estado VARCHAR2(30) NOT NULL,
 entrevista_id NUMBER NOT NULL,
 CONSTRAINT pk_informe
 PRIMARY KEY (informe_id),
 CONSTRAINT fk_informe_entrevista
 FOREIGN KEY (entrevista_id)
 REFERENCES ENTREVISTA (entrevista_id),
 CONSTRAINT uk_informe_entrevista
 UNIQUE (entrevista_id),
 CONSTRAINT ck_informe_estado
 CHECK (
 estado IN (
 'EN_REVISION',
 'COMPLETADO'
 )
 )
);
ALTER TABLE INFORMEPSICOLABORAL
ADD CONSTRAINT ck_informe_fecha
CHECK (fecha_generacion IS NOT NULL);

/* ============================================================
 INDICES PARA FOREIGN KEYS
 ============================================================ */
CREATE INDEX idx_cargo_familiacargo
 ON CARGO (familiacargo_id);
CREATE INDEX idx_solicitud_candidato
 ON SOLICITUDEVALUACION (candidato_id);
CREATE INDEX idx_solicitud_cargo
 ON SOLICITUDEVALUACION (cargo_id);
CREATE INDEX idx_solicitud_analista
 ON SOLICITUDEVALUACION (analista_id);
CREATE INDEX idx_documento_solicitud
 ON DOCUMENTO (solicitud_id);
CREATE INDEX idx_entrevista_psicologo
 ON ENTREVISTA (psicologo_id);

/* ============================================================
 DATOS: ANALISTAS
 ============================================================ */
INSERT INTO ANALISTA (nombre, correo)
VALUES ('Juan Pérez', 'juan.perez\@empresa.cl');
INSERT INTO ANALISTA (nombre, correo)
VALUES ('María González', 'maria.gonzalez\@empresa.cl');
INSERT INTO ANALISTA (nombre, correo)
VALUES ('Carlos Soto', 'carlos.soto\@empresa.cl');
INSERT INTO ANALISTA (nombre, correo)
VALUES ('Fernanda Muñoz', 'fernanda.munoz\@empresa.cl');
INSERT INTO ANALISTA (nombre, correo)
VALUES ('Diego Rojas', 'diego.rojas\@empresa.cl');

/* ============================================================
 DATOS: PSICOLOGOS
 ============================================================ */
INSERT INTO PSICOLOGO (nombre, correo)
VALUES ('Carolina Silva', 'carolina.silva\@empresa.cl');
INSERT INTO PSICOLOGO (nombre, correo)
VALUES ('Andrés Morales', 'andres.morales\@empresa.cl');
INSERT INTO PSICOLOGO (nombre, correo)
VALUES ('Valentina Torres', 'valentina.torres\@empresa.cl');
INSERT INTO PSICOLOGO (nombre, correo)
VALUES ('Felipe Vargas', 'felipe.vargas\@empresa.cl');
INSERT INTO PSICOLOGO (nombre, correo)
VALUES ('Camila Fuentes', 'camila.fuentes\@empresa.cl');

/* ============================================================
 DATOS: CANDIDATOS
 ============================================================ */
INSERT INTO CANDIDATO (nombre)
VALUES ('Pedro Martínez');
INSERT INTO CANDIDATO (nombre)
VALUES ('Sofía Ramírez');
INSERT INTO CANDIDATO (nombre)
VALUES ('Tomás Herrera');
INSERT INTO CANDIDATO (nombre)
VALUES ('Daniela Contreras');
INSERT INTO CANDIDATO (nombre)
VALUES ('Matías Fuentes');

/* ============================================================
 DATOS: FAMILIAS DE CARGO
 ============================================================ */
INSERT INTO FAMILIACARGO (nombre_familia, descripcion)
VALUES (
 'Tecnología',
 'Cargos relacionados con informática y tecnología'
);
INSERT INTO FAMILIACARGO (nombre_familia, descripcion)
VALUES (
 'Administración',
 'Cargos relacionados con gestión administrativa'
);
INSERT INTO FAMILIACARGO (nombre_familia, descripcion)
VALUES (
 'Finanzas',
 'Cargos relacionados con contabilidad y finanzas'
);
INSERT INTO FAMILIACARGO (nombre_familia, descripcion)
VALUES (
 'Recursos Humanos',
 'Cargos relacionados con gestión de personas'
);
INSERT INTO FAMILIACARGO (nombre_familia, descripcion)
VALUES (
 'Comercial',
 'Cargos relacionados con ventas y atención comercial'
);

/* ============================================================
 DATOS: CARGOS
 ============================================================ */
INSERT INTO CARGO (nombre_cargo, familiacargo_id)
SELECT
 'Analista de Datos',
 familiacargo_id
FROM FAMILIACARGO
WHERE nombre_familia = 'Tecnología';
INSERT INTO CARGO (nombre_cargo, familiacargo_id)
SELECT
 'Asistente Administrativo',
 familiacargo_id
FROM FAMILIACARGO
WHERE nombre_familia = 'Administración';
INSERT INTO CARGO (nombre_cargo, familiacargo_id)
SELECT
 'Analista Financiero',
 familiacargo_id
FROM FAMILIACARGO
WHERE nombre_familia = 'Finanzas';
INSERT INTO CARGO (nombre_cargo, familiacargo_id)
SELECT
 'Analista de Recursos Humanos',
 familiacargo_id
FROM FAMILIACARGO
WHERE nombre_familia = 'Recursos Humanos';
INSERT INTO CARGO (nombre_cargo, familiacargo_id)
SELECT
 'Ejecutivo Comercial',
 familiacargo_id
FROM FAMILIACARGO
WHERE nombre_familia = 'Comercial';

/* ============================================================
 DATOS: SOLICITUDES DE EVALUACION
 ============================================================ */
INSERT INTO SOLICITUDEVALUACION
 (solicitud_id, fecha_solicitud, estado,
 candidato_id, cargo_id, analista_id)
SELECT
 'SOL001',
 DATE '2026-09-01',
 'COMPLETADA',
 c.candidato_id,
 ca.cargo_id,
 a.analista_id
FROM CANDIDATO c
CROSS JOIN CARGO ca
CROSS JOIN ANALISTA a
WHERE c.nombre = 'Pedro Martínez'
 AND ca.nombre_cargo = 'Analista de Datos'
 AND a.correo = 'juan.perez\@empresa.cl';

INSERT INTO SOLICITUDEVALUACION
 (solicitud_id, fecha_solicitud, estado,
 candidato_id, cargo_id, analista_id)
SELECT
 'SOL002',
 DATE '2026-09-02',
 'COMPLETADA',
 c.candidato_id,
 ca.cargo_id,
 a.analista_id
FROM CANDIDATO c
CROSS JOIN CARGO ca
CROSS JOIN ANALISTA a
WHERE c.nombre = 'Sofía Ramírez'
 AND ca.nombre_cargo = 'Asistente Administrativo'
 AND a.correo = 'maria.gonzalez\@empresa.cl';

INSERT INTO SOLICITUDEVALUACION
 (solicitud_id, fecha_solicitud, estado,
 candidato_id, cargo_id, analista_id)
SELECT
 'SOL003',
 DATE '2026-09-03',
 'PENDIENTE',
 c.candidato_id,
 ca.cargo_id,
 a.analista_id
FROM CANDIDATO c
CROSS JOIN CARGO ca
CROSS JOIN ANALISTA a
WHERE c.nombre = 'Tomás Herrera'
 AND ca.nombre_cargo = 'Analista Financiero'
 AND a.correo = 'carlos.soto\@empresa.cl';

INSERT INTO SOLICITUDEVALUACION
 (solicitud_id, fecha_solicitud, estado,
 candidato_id, cargo_id, analista_id)
SELECT
 'SOL004',
 DATE '2026-09-04',
 'COMPLETADA',
 c.candidato_id,
 ca.cargo_id,
 a.analista_id
FROM CANDIDATO c
CROSS JOIN CARGO ca
CROSS JOIN ANALISTA a
WHERE c.nombre = 'Daniela Contreras'
 AND ca.nombre_cargo = 'Analista de Recursos Humanos'
 AND a.correo = 'fernanda.munoz\@empresa.cl';

INSERT INTO SOLICITUDEVALUACION
 (solicitud_id, fecha_solicitud, estado,
 candidato_id, cargo_id, analista_id)
SELECT
 'SOL005',
 DATE '2026-09-05',
 'EN_EVALUACION',
 c.candidato_id,
 ca.cargo_id,
 a.analista_id
FROM CANDIDATO c
CROSS JOIN CARGO ca
CROSS JOIN ANALISTA a
WHERE c.nombre = 'Matías Fuentes'
 AND ca.nombre_cargo = 'Ejecutivo Comercial'
 AND a.correo = 'diego.rojas\@empresa.cl';

/* ============================================================
 DATOS: DOCUMENTOS
 ============================================================ */
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('CV', DATE '2026-09-01', 'SOL001');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Pauta de entrevista', DATE '2026-09-01', 'SOL001');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Transcripción', DATE '2026-09-02', 'SOL001');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Informe psicolaboral', DATE '2026-09-03', 'SOL001');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('CV', DATE '2026-09-02', 'SOL002');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Pauta de entrevista', DATE '2026-09-02', 'SOL002');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Transcripción', DATE '2026-09-03', 'SOL002');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('CV', DATE '2026-09-03', 'SOL003');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Pauta de entrevista', DATE '2026-09-03', 'SOL003');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('CV', DATE '2026-09-04', 'SOL004');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Pauta de entrevista', DATE '2026-09-04', 'SOL004');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Transcripción', DATE '2026-09-06', 'SOL004');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Informe psicolaboral', DATE '2026-09-07', 'SOL004');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('CV', DATE '2026-09-05', 'SOL005');
INSERT INTO DOCUMENTO
 (tipo_doc, fecha_creacion, solicitud_id)
VALUES ('Pauta de entrevista', DATE '2026-09-05', 'SOL005');

/* ============================================================
 DATOS: ENTREVISTAS
 Solo se crean para solicitudes que ya llegaron a evaluación.
 ============================================================ */
INSERT INTO ENTREVISTA
 (fecha_entrevista, observaciones, transcripcion,
 solicitud_id, psicologo_id)
SELECT
 DATE '2026-09-02',
 'El candidato demuestra capacidad analítica y buena comunicación.',
 'Durante la entrevista explicó su experiencia trabajando con datos y herramientas tecnológicas.',
 'SOL001',
 psicologo_id
FROM PSICOLOGO
WHERE correo = 'carolina.silva\@empresa.cl';

INSERT INTO ENTREVISTA
 (fecha_entrevista, observaciones, transcripcion,
 solicitud_id, psicologo_id)
SELECT
 DATE '2026-09-03',
 'Presenta buena disposición y organización.',
 'El candidato describió experiencias relacionadas con organización de documentos y atención de requerimientos administrativos.',
 'SOL002',
 psicologo_id
FROM PSICOLOGO
WHERE correo = 'andres.morales\@empresa.cl';

INSERT INTO ENTREVISTA
 (fecha_entrevista, observaciones, transcripcion,
 solicitud_id, psicologo_id)
SELECT
 DATE '2026-09-06',
 'Buena comunicación interpersonal y orientación al trabajo en equipo.',
 'El candidato explicó experiencias relacionadas con selección, comunicación interna y gestión de personas.',
 'SOL004',
 psicologo_id
FROM PSICOLOGO
WHERE correo = 'felipe.vargas\@empresa.cl';

INSERT INTO ENTREVISTA
 (fecha_entrevista, observaciones, transcripcion,
 solicitud_id, psicologo_id)
SELECT
 DATE '2026-09-07',
 'Muestra orientación al cliente y habilidades de negociación.',
 'El candidato describió experiencias en ventas, atención de clientes y cumplimiento de objetivos comerciales.',
 'SOL005',
 psicologo_id
FROM PSICOLOGO
WHERE correo = 'camila.fuentes\@empresa.cl';

/* ============================================================
 DATOS: INFORMES PSICOLABORALES
 ============================================================ */
INSERT INTO INFORMEPSICOLABORAL
 (fecha_generacion, contenido, estado, entrevista_id)
SELECT
 DATE '2026-09-03',
 'Evaluación favorable. Presenta competencias analíticas, comunicación efectiva y capacidad de adaptación.',
 'COMPLETADO',
 entrevista_id
FROM ENTREVISTA
WHERE solicitud_id = 'SOL001';

INSERT INTO INFORMEPSICOLABORAL
 (fecha_generacion, contenido, estado, entrevista_id)
SELECT
 DATE '2026-09-04',
 'Evaluación favorable. Destaca por organización, responsabilidad y disposición para aprender.',
 'COMPLETADO',
 entrevista_id
FROM ENTREVISTA
WHERE solicitud_id = 'SOL002';

INSERT INTO INFORMEPSICOLABORAL
 (fecha_generacion, contenido, estado, entrevista_id)
SELECT
 DATE '2026-09-07',
 'Evaluación favorable. Presenta habilidades interpersonales, organización y trabajo en equipo.',
 'COMPLETADO',
 entrevista_id
FROM ENTREVISTA
WHERE solicitud_id = 'SOL004';

INSERT INTO INFORMEPSICOLABORAL
 (fecha_generacion, contenido, estado, entrevista_id)
SELECT
 DATE '2026-09-08',
 'Evaluación en proceso de revisión. Destaca por orientación al cliente y capacidad de negociación.',
 'EN_REVISION',
 entrevista_id
FROM ENTREVISTA
WHERE solicitud_id = 'SOL005';

COMMIT;

/* ============================================================
 CONSULTAS DE COMPROBACION
 ============================================================ */
SELECT * FROM ANALISTA;
SELECT * FROM PSICOLOGO;
SELECT * FROM CANDIDATO;
SELECT * FROM FAMILIACARGO;
SELECT * FROM CARGO;
SELECT * FROM SOLICITUDEVALUACION;
SELECT * FROM DOCUMENTO;
SELECT * FROM ENTREVISTA;
SELECT * FROM INFORMEPSICOLABORAL;

/* ============================================================
 CONSULTA GENERAL DEL PROCESO
 ============================================================ */
SELECT
 s.solicitud_id AS solicitud,
 c.nombre AS candidato,
 ca.nombre_cargo AS cargo,
 fc.nombre_familia AS familia,
 a.nombre AS analista,
 p.nombre AS psicologo,
 s.estado AS estado_solicitud,
 e.fecha_entrevista,
 i.estado AS estado_informe
FROM SOLICITUDEVALUACION s
JOIN CANDIDATO c
 ON s.candidato_id = c.candidato_id
JOIN CARGO ca
 ON s.cargo_id = ca.cargo_id
JOIN FAMILIACARGO fc
 ON ca.familiacargo_id = fc.familiacargo_id
JOIN ANALISTA a
 ON s.analista_id = a.analista_id
LEFT JOIN ENTREVISTA e
 ON s.solicitud_id = e.solicitud_id
LEFT JOIN PSICOLOGO p
 ON e.psicologo_id = p.psicologo_id
LEFT JOIN INFORMEPSICOLABORAL i
 ON e.entrevista_id = i.entrevista_id
ORDER BY s.solicitud_id;

/* ============================================================
 CONSULTA DE DOCUMENTOS POR SOLICITUD
 ============================================================ */
SELECT
 s.solicitud_id AS solicitud,
 c.nombre AS candidato,
 d.tipo_doc,
 d.fecha_creacion
FROM SOLICITUDEVALUACION s
JOIN CANDIDATO c
 ON s.candidato_id = c.candidato_id
JOIN DOCUMENTO d
 ON s.solicitud_id = d.solicitud_id
ORDER BY s.solicitud_id, d.documento_id;

/* ============================================================
Procedimientos Almacenados: Estos procedimientos automatizan el cambio de estados
de las solicitudes y el pricesamiento por familia de cargo.
 ============================================================
Procedimiento sin parámetros:
*/
CREATE OR REPLACE PROCEDURE pr_sincronizar_estados
AS
BEGIN
    UPDATE SOLICITUDEVALUACION s
    SET estado =
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM ENTREVISTA e
                JOIN INFORMEPSICOLABORAL i
                    ON i.entrevista_id = e.entrevista_id
                WHERE e.solicitud_id = s.solicitud_id
                  AND i.estado = 'COMPLETADO'
            ) THEN 'COMPLETADA'
            WHEN EXISTS (
                SELECT 1
                FROM ENTREVISTA e
                WHERE e.solicitud_id = s.solicitud_id
            ) THEN 'EN_EVALUACION'
            ELSE 'PENDIENTE'
        END
    WHERE s.estado <> 'CANCELADA';
    DBMS_OUTPUT.PUT_LINE(
        'Estados de solicitudes sincronizados.'
    );
END;
/

/*Procedimiento con parámetros:*/
CREATE OR REPLACE PROCEDURE pr_procesar_familia (
    p_familiacargo_id IN NUMBER,
    p_cantidad_actualizada OUT NUMBER
)
AS
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_existe
    FROM FAMILIACARGO
    WHERE familiacargo_id = p_familiacargo_id;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'La familia de cargo no existe.'
        );
    END IF;
    UPDATE SOLICITUDEVALUACION s
    SET estado =
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM ENTREVISTA e
                JOIN INFORMEPSICOLABORAL i
                    ON i.entrevista_id = e.entrevista_id
                WHERE e.solicitud_id = s.solicitud_id
                  AND i.estado = 'COMPLETADO'
            ) THEN 'COMPLETADA'
            WHEN EXISTS (
                SELECT 1
                FROM ENTREVISTA e
                WHERE e.solicitud_id = s.solicitud_id
            ) THEN 'EN_EVALUACION'
            ELSE 'PENDIENTE'
        END
    WHERE s.estado <> 'CANCELADA'
      AND s.cargo_id IN (
          SELECT c.cargo_id
          FROM CARGO c
          WHERE c.familiacargo_id = p_familiacargo_id
      );
    p_cantidad_actualizada := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE(
        'Solicitudes actualizadas: ' ||
        p_cantidad_actualizada
    );
END;
/

/*Procedimiento para normalizar el estado de una solicitud,
asegurando que esté en mayúsculas y sin espacios al inicio o final.*/
CREATE OR REPLACE PROCEDURE pr_normalizar_estado (
    p_estado IN OUT VARCHAR2
)
AS
BEGIN
    p_estado := UPPER(TRIM(p_estado));
    IF p_estado NOT IN (
        'PENDIENTE',
        'EN_EVALUACION',
        'COMPLETADA',
        'CANCELADA'
    ) THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Estado de solicitud no valido.'
        );
    END IF;
END;
/

/*Funciones: Las funciones devuelven un valor, por lo que sirven para obtener
indicadores y consuñ¿ltar informavción específica.
Función sin parámetros:*/
CREATE OR REPLACE FUNCTION fn_porcentaje_completadas
RETURN NUMBER
AS
    v_total NUMBER;
    v_completadas NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM SOLICITUDEVALUACION;
    SELECT COUNT(*)
    INTO v_completadas
    FROM SOLICITUDEVALUACION
    WHERE estado = 'COMPLETADA';
    IF v_total = 0 THEN
        RETURN 0;
    END IF;
    RETURN ROUND(
        (v_completadas / v_total) * 100,
        2
    );
END;
/

/*Función con parámetros:*/
CREATE OR REPLACE FUNCTION fn_total_documentos (
    p_solicitud_id IN VARCHAR2
)
RETURN NUMBER
AS
    v_existe NUMBER;
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_existe
    FROM SOLICITUDEVALUACION
    WHERE solicitud_id = p_solicitud_id;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'La solicitud indicada no existe.'
        );
    END IF;
    SELECT COUNT(*)
    INTO v_total
    FROM DOCUMENTO
    WHERE solicitud_id = p_solicitud_id;
    RETURN v_total;
END;
/

/*Package con elementos públicos y privados:
Especificación pública:*/
CREATE OR REPLACE PACKAGE PKG_EVALUACION
AS
    PROCEDURE actualizar_estado (
        p_solicitud_id IN VARCHAR2,
        p_estado_resultante OUT VARCHAR2
    );
    FUNCTION total_documentos (
        p_solicitud_id IN VARCHAR2
    ) RETURN NUMBER;
END PKG_EVALUACION;
/

/*Cuerpo del package con implementación privada:*/
CREATE OR REPLACE PACKAGE BODY PKG_EVALUACION
AS
    -- Elemento privado
    FUNCTION estado_sugerido (
        p_solicitud_id IN VARCHAR2
    )
    RETURN VARCHAR2
    AS
        v_estado_actual VARCHAR2(30);
        v_informe_completado NUMBER;
        v_tiene_entrevista NUMBER;
    BEGIN
        SELECT estado
        INTO v_estado_actual
        FROM SOLICITUDEVALUACION
        WHERE solicitud_id = p_solicitud_id;
        IF v_estado_actual = 'CANCELADA' THEN
            RETURN 'CANCELADA';
        END IF;
        SELECT COUNT(*)
        INTO v_informe_completado
        FROM ENTREVISTA e
        JOIN INFORMEPSICOLABORAL i
            ON i.entrevista_id = e.entrevista_id
        WHERE e.solicitud_id = p_solicitud_id
          AND i.estado = 'COMPLETADO';
        IF v_informe_completado > 0 THEN
            RETURN 'COMPLETADA';
        END IF;
        SELECT COUNT(*)
        INTO v_tiene_entrevista
        FROM ENTREVISTA
        WHERE solicitud_id = p_solicitud_id;
        IF v_tiene_entrevista > 0 THEN
            RETURN 'EN_EVALUACION';
        END IF;
        RETURN 'PENDIENTE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'La solicitud no existe.'
            );
    END estado_sugerido;
    -- Elemento público
    PROCEDURE actualizar_estado (
    p_solicitud_id IN VARCHAR2,
    p_estado_resultante OUT VARCHAR2
)
AS
    v_estado VARCHAR2(30);
BEGIN
    -- Obtener el estado sugerido
    v_estado := estado_sugerido(p_solicitud_id);
    -- Actualizar la solicitud
    UPDATE SOLICITUDEVALUACION
    SET estado = v_estado
    WHERE solicitud_id = p_solicitud_id;
    -- Comprobar si existe la solicitud
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'La solicitud no existe.'
        );
    END IF;

    -- Devolver el estado actualizado
    p_estado_resultante := v_estado;
END actualizar_estado;
    -- Elemento público
    FUNCTION total_documentos (
        p_solicitud_id IN VARCHAR2
    )
    RETURN NUMBER
    AS
        v_total NUMBER;
        v_existe NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_existe
        FROM SOLICITUDEVALUACION
        WHERE solicitud_id = p_solicitud_id;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20006,
                'La solicitud indicada no existe.'
            );

        END IF;
        SELECT COUNT(*)
        INTO v_total
        FROM DOCUMENTO
        WHERE solicitud_id = p_solicitud_id;
        RETURN v_total;
    END total_documentos;
END PKG_EVALUACION;
/

/*Triggers por fila y por sentencia: Estos triggers se activan automáticamente ante cambios
 en la tabla SOLICITUDEVALUACION, asegurando que el estado de la solicitud se mantenga consistente con las entrevistas e informes asociados.*/
/*Tabla para registrar las operaciones de documentos:*/
CREATE TABLE AUDITORIA_CARGA_DOCUMENTOS (
    auditoria_id NUMBER GENERATED ALWAYS AS IDENTITY,
    fecha_evento TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    usuario VARCHAR2(128) NOT NULL,
    operacion VARCHAR2(20) NOT NULL,
    detalle VARCHAR2(200),
    CONSTRAINT pk_auditoria_documentos
        PRIMARY KEY (auditoria_id)
);
/

/*Trigger por fila: Se ejecuta una vez por cada entrevista insertada o modificada*/
CREATE OR REPLACE TRIGGER trg_validar_fecha_entrevista
BEFORE INSERT OR UPDATE OF fecha_entrevista, solicitud_id
ON ENTREVISTA
FOR EACH ROW
DECLARE
    v_fecha_solicitud DATE;
BEGIN
    SELECT fecha_solicitud
    INTO v_fecha_solicitud
    FROM SOLICITUDEVALUACION
    WHERE solicitud_id = :NEW.solicitud_id;
    IF TRUNC(:NEW.fecha_entrevista)
       < TRUNC(v_fecha_solicitud) THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'La entrevista no puede ser anterior a la solicitud.'
        );
    END IF;
END;
/

/*Trigger por sentencia: Se ejecuta una vez por cada operación de inserción, actualización o eliminación en la tabla SOLICITUDEVALUACION*/
CREATE OR REPLACE TRIGGER trg_registrar_carga_documentos
AFTER INSERT ON DOCUMENTO
BEGIN
    INSERT INTO AUDITORIA_CARGA_DOCUMENTOS (
        usuario,
        operacion,
        detalle
    )
    VALUES (
        USER,
        'INSERT',
        'Sentencia de insercion ejecutada en DOCUMENTO'
    );
END;

/
/*Pruebas:*/
SET SERVEROUTPUT ON;
DECLARE
    v_estado VARCHAR2(30);
    v_estado_normalizado VARCHAR2(30) := ' en_evaluacion ';
    v_porcentaje NUMBER;
    v_documentos NUMBER;
    v_familia_id NUMBER;
    v_actualizadas NUMBER;
BEGIN
    -- 1. Normalizar y validar un estado
    pr_normalizar_estado(v_estado_normalizado);
    DBMS_OUTPUT.PUT_LINE(
        'Estado normalizado: ' || v_estado_normalizado
    );
    -- 2. Sincronizar los estados de todas las solicitudes
    pr_sincronizar_estados;
    -- 3. Actualizar una solicitud mediante el package
    PKG_EVALUACION.actualizar_estado(
        'SOL002',
        v_estado
    );
    DBMS_OUTPUT.PUT_LINE(
        'Estado de SOL002: ' || v_estado
    );
    -- 4. Procesar una familia de cargos
    SELECT MIN(familiacargo_id)
    INTO v_familia_id
    FROM FAMILIACARGO;
    IF v_familia_id IS NOT NULL THEN
        pr_procesar_familia(
            v_familia_id,
            v_actualizadas
        );
    END IF;
    -- 5. Consultar el porcentaje de solicitudes completadas
    v_porcentaje := fn_porcentaje_completadas;
    DBMS_OUTPUT.PUT_LINE(
        'Porcentaje completado: ' || v_porcentaje || '%'
    );
    -- 6. Consultar documentos de una solicitud
    v_documentos := PKG_EVALUACION.total_documentos('SOL001');
    DBMS_OUTPUT.PUT_LINE(
        'Documentos de SOL001: ' || v_documentos
    );
END;
/

SELECT solicitud_id, estado
FROM SOLICITUDEVALUACION
ORDER BY solicitud_id;
SELECT *
FROM AUDITORIA_CARGA_DOCUMENTOS
ORDER BY auditoria_id;
SELECT fn_porcentaje_completadas AS porcentaje_completadas
FROM DUAL;
SELECT fn_total_documentos('SOL001') AS total_documentos
FROM DUAL;

/* ============================================================
   TRIGGER POR FILA: SINCRONIZAR ESTADO DE LA SOLICITUD
   Cuando un informe queda COMPLETADO, la solicitud asociada
   también pasa a COMPLETADA.
   ============================================================ */
CREATE OR REPLACE TRIGGER trg_sincronizar_informe
AFTER INSERT OR UPDATE OF estado
ON INFORMEPSICOLABORAL
FOR EACH ROW
BEGIN
    IF :NEW.estado = 'COMPLETADO' THEN
        UPDATE SOLICITUDEVALUACION
        SET estado = 'COMPLETADA'
        WHERE solicitud_id = (
            SELECT solicitud_id
            FROM ENTREVISTA
            WHERE entrevista_id = :NEW.entrevista_id
        );
    END IF;
END;
/

/* ============================================================
   TABLA DE AUDITORÍA DE ESTADOS
   Guarda cada cambio de estado de una solicitud.
   ============================================================ */
CREATE TABLE AUDITORIA_ESTADO (
    auditoria_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    solicitud_id VARCHAR2(20) NOT NULL,
    estado_anterior VARCHAR2(30),
    estado_nuevo VARCHAR2(30) NOT NULL,
    usuario VARCHAR2(128) NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

/* ============================================================
   TRIGGER POR FILA: AUDITAR CAMBIOS DE ESTADO
   Registra el estado anterior, el nuevo estado, el usuario
   y la fecha de cada cambio realizado en una solicitud.
   ============================================================ */
CREATE OR REPLACE TRIGGER trg_auditar_estado_solicitud
AFTER UPDATE OF estado
ON SOLICITUDEVALUACION
FOR EACH ROW
BEGIN
    IF :OLD.estado <> :NEW.estado THEN
        INSERT INTO AUDITORIA_ESTADO (
            solicitud_id,
            estado_anterior,
            estado_nuevo,
            usuario
        )
        VALUES (
            :NEW.solicitud_id,
            :OLD.estado,
            :NEW.estado,
            USER
        );
    END IF;
END;
/

/* ============================================================
   COMPROBACIÓN DE TRIGGERS
   Permite revisar si los triggers están habilitados.
   ============================================================ */
SELECT trigger_name, status, table_name
FROM USER_TRIGGERS
WHERE trigger_name IN (
    'TRG_VALIDAR_FECHA_ENTREVISTA',
    'TRG_REGISTRAR_CARGA_DOCUMENTOS',
    'TRG_SINCRONIZAR_INFORME',
    'TRG_AUDITAR_ESTADO_SOLICITUD'
)
ORDER BY trigger_name;

/* ============================================================
   PRUEBA 1: SINCRONIZACIÓN DEL INFORME
   El informe 4 corresponde a SOL005 en los datos de ejemplo.
   Se cambia a COMPLETADO y se comprueba que la solicitud
   también quede COMPLETADA. Luego se deshace la prueba.
   ============================================================ */
SAVEPOINT prueba_informe;
UPDATE INFORMEPSICOLABORAL
SET estado = 'COMPLETADO'
WHERE informe_id = 4;
SELECT
    i.informe_id,
    i.estado AS estado_informe,
    e.solicitud_id,
    s.estado AS estado_solicitud
FROM INFORMEPSICOLABORAL i
JOIN ENTREVISTA e
    ON e.entrevista_id = i.entrevista_id
JOIN SOLICITUDEVALUACION s
    ON s.solicitud_id = e.solicitud_id
WHERE i.informe_id = 4;
ROLLBACK TO prueba_informe;

/* ============================================================
   PRUEBA 2: AUDITORÍA DE CAMBIOS DE ESTADO
   SOL003 comienza en PENDIENTE. Se cambia temporalmente a
   EN_EVALUACION y se revisa el registro de auditoría.
   Luego se deshace la prueba.
   ============================================================ */
SAVEPOINT prueba_auditoria;
UPDATE SOLICITUDEVALUACION
SET estado = 'EN_EVALUACION'
WHERE solicitud_id = 'SOL003';
SELECT *
FROM AUDITORIA_ESTADO
ORDER BY auditoria_id DESC;
ROLLBACK TO prueba_auditoria;

/* ============================================================
   PRUEBA 3: AUDITORÍA DE CARGA DE DOCUMENTOS
   Inserta un documento de prueba para SOL004 y comprueba que
   se registre la operación en AUDITORIA_CARGA_DOCUMENTOS.
   Luego se deshace la prueba.
   ============================================================ */
SAVEPOINT prueba_documento;
INSERT INTO DOCUMENTO (
    tipo_doc,
    fecha_creacion,
    solicitud_id
)
VALUES (
    'PRUEBA',
    SYSDATE,
    'SOL004'
);
SELECT *
FROM AUDITORIA_CARGA_DOCUMENTOS
ORDER BY auditoria_id DESC;
ROLLBACK TO prueba_documento;

/* ============================================================
   PRUEBA 4: VALIDACIÓN DE FECHA DE ENTREVISTA (OPCIONAL)
   El trigger debe rechazar una entrevista anterior a la fecha
   de solicitud. Ejecutar por separado, porque se espera que
   genere el error -20002.*/

   INSERT INTO ENTREVISTA (
       fecha_entrevista, observaciones, transcripcion,
       solicitud_id, psicologo_id
   )
   SELECT DATE '2020-01-01', 'Prueba de trigger', 'Prueba',
          s.solicitud_id, p.psicologo_id
   FROM SOLICITUDEVALUACION s
   CROSS JOIN PSICOLOGO p
   WHERE s.solicitud_id = 'SOL003'
     AND p.correo = 'carolina.silva@empresa.cl';

   ============================================================ */
/* ============================================================
   CONSULTA FINAL: ESTADOS DE LAS SOLICITUDES
   ============================================================ */
SELECT solicitud_id, estado
FROM SOLICITUDEVALUACION
ORDER BY solicitud_id;

/* ============================================================
   CONSULTA FINAL: AUDITORÍA DE DOCUMENTOS
   ============================================================ */
SELECT *
FROM AUDITORIA_CARGA_DOCUMENTOS
ORDER BY auditoria_id;

/* ============================================================
   CONSULTA FINAL: AUDITORÍA DE ESTADOS
   ============================================================ */
SELECT *
FROM AUDITORIA_ESTADO
ORDER BY auditoria_id;
