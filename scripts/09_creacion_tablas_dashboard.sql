-- =============================================
-- ELIMINACIÓN DE VISTAS EXISTENTES (SI APLICA)
-- =============================================
DROP VIEW IF EXISTS rul_por_motor CASCADE;
DROP VIEW IF EXISTS sensores_clave CASCADE;
DROP VIEW IF EXISTS dashboard_consolidado CASCADE;

-- =============================================
-- VISTA 1: RUL POR MOTOR (ESTADO CRÍTICO)
-- =============================================
CREATE OR REPLACE VIEW rul_por_motor AS
WITH motor_life AS (
    SELECT 
        motor_id, 
        MAX(time_in_cycles) AS total_cycles
    FROM cycles
    GROUP BY motor_id
)
SELECT 
    m.original_id AS motor_id,
    d.name AS dataset,
    c.time_in_cycles,
    (ml.total_cycles - c.time_in_cycles) AS rul,
    CASE WHEN (ml.total_cycles - c.time_in_cycles) < 20 
        THEN 1 ELSE 0 END AS critico,
    c.op_setting1,
    c.op_setting2,
    c.op_setting3
FROM cycles c
JOIN motors m ON c.motor_id = m.id
JOIN datasets d ON m.dataset_id = d.id
JOIN motor_life ml ON m.id = ml.motor_id;

-- =============================================
-- VISTA 2: SENSORES CLAVE (CON TENDENCIAS)
-- =============================================
CREATE OR REPLACE VIEW sensores_clave AS
SELECT 
    m.original_id AS motor_id,
    d.name AS dataset,
    c.time_in_cycles,
    s.sensor_4,
    s.sensor_11,
    s.sensor_15,
    s.sensor_4 - LAG(s.sensor_4) OVER (PARTITION BY m.id ORDER BY c.time_in_cycles) AS diff_sensor_4,
    s.sensor_11 - LAG(s.sensor_11) OVER (PARTITION BY m.id ORDER BY c.time_in_cycles) AS diff_sensor_11,
    s.sensor_15 - LAG(s.sensor_15) OVER (PARTition BY m.id ORDER BY c.time_in_cycles) AS diff_sensor_15
FROM cycles c
JOIN motors m ON c.motor_id = m.id
JOIN datasets d ON m.dataset_id = d.id
JOIN sensor_measurements s ON c.id = s.cycle_id;

-- =============================================
-- VISTA 3: DASHBOARD CONSOLIDADO (TODO EN UNO)
-- =============================================
CREATE OR REPLACE VIEW dashboard_consolidado AS
SELECT 
    v.motor_id,
    v.dataset,
    v.time_in_cycles,
    v.rul,
    v.critico,
    v.op_setting1,
    v.op_setting2,
    v.op_setting3,
    s.sensor_4,
    s.sensor_11,
    s.sensor_15,
    s.diff_sensor_4,
    s.diff_sensor_11,
    s.diff_sensor_15,
    CASE 
        WHEN v.rul < 10 THEN 'FALLA INMINENTE'
        WHEN v.rul BETWEEN 10 AND 20 THEN 'ALTO RIESGO'
        ELSE 'ESTABLE' 
    END AS estado_motor
FROM rul_por_motor v
JOIN sensores_clave s 
    ON v.motor_id = s.motor_id 
    AND v.time_in_cycles = s.time_in_cycles;

-- =============================================
-- VISTA 4: KPIs ESPECÍFICOS PARA TABLEAU
-- =============================================
CREATE OR REPLACE VIEW kpis_tableau AS
SELECT 
    -- KPI 1: Motores críticos actuales
    (SELECT COUNT(DISTINCT motor_id) 
     FROM rul_por_motor 
     WHERE critico = 1 
        AND time_in_cycles = (SELECT MAX(time_in_cycles) FROM rul_por_motor)
    ) AS motores_criticos,
    
    --=======================================
    -- KPI 2: Correlación sensores vs RUL
    --===================================
    (SELECT CORR(sensor_4, rul) FROM dashboard_consolidado) AS corr_sensor4,
    (SELECT CORR(sensor_11, rul) FROM dashboard_consolidado) AS corr_sensor11,
    (SELECT CORR(sensor_15, rul) FROM dashboard_consolidado) AS corr_sensor15,
    
    -- KPI 3: Distribución RUL por dataset (FD001)
    (SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY rul) 
     FROM rul_por_motor 
     WHERE time_in_cycles = 1 AND dataset = 'FD001') AS fd001_q1,
    
    -- KPI 4: Distribución RUL por dataset (FD002)
    (SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY rul) 
     FROM rul_por_motor 
     WHERE time_in_cycles = 1 AND dataset = 'FD002') AS fd002_q1;

--==========================================
-- VISTA ÚNICA PARA DASHBOARD CONSOLIDADO
--==========================================
drop view vulcan_forge CASCADE;
-- Paso 1: Eliminar la vista existente (si es necesario)
DROP VIEW IF EXISTS vulcan_dashboard CASCADE;

-- Paso 2: Crear la vista con la estructura CORRECTA
CREATE OR REPLACE VIEW vulcan_dashboard AS
WITH motor_life AS (
    SELECT 
        motor_id, 
        MAX(time_in_cycles) AS total_cycles
    FROM cycles
    GROUP BY motor_id
),
rul_data AS (
    SELECT 
        m.original_id AS motor_id,
        d.name AS dataset,
        c.time_in_cycles,
        (ml.total_cycles - c.time_in_cycles) AS rul,
        CASE WHEN (ml.total_cycles - c.time_in_cycles) < 20 
            THEN 1 ELSE 0 END AS critico,
        c.op_setting1,
        c.op_setting2,
        c.op_setting3
    FROM cycles c
    JOIN motors m ON c.motor_id = m.id
    JOIN datasets d ON m.dataset_id = d.id
    JOIN motor_life ml ON m.id = ml.motor_id
),
sensor_data AS (
    SELECT 
        m.original_id AS motor_id,
        c.time_in_cycles,
        s.sensor_4,
        s.sensor_11,
        s.sensor_15,
        s.sensor_4 - LAG(s.sensor_4) OVER (
            PARTITION BY m.id ORDER BY c.time_in_cycles
        ) AS diff_sensor_4,
        s.sensor_11 - LAG(s.sensor_11) OVER (
            PARTITION BY m.id ORDER BY c.time_in_cycles
        ) AS diff_sensor_11,
        s.sensor_15 - LAG(s.sensor_15) OVER (
            PARTITION BY m.id ORDER BY c.time_in_cycles
        ) AS diff_sensor_15
    FROM cycles c
    JOIN motors m ON c.motor_id = m.id
    JOIN sensor_measurements s ON c.id = s.cycle_id
)
SELECT 
    r.motor_id,
    r.dataset,
    r.time_in_cycles,
    r.rul,
    r.critico,
    r.op_setting1,
    r.op_setting2,
    r.op_setting3,
    s.sensor_4,
    s.sensor_11,
    s.sensor_15,
    s.diff_sensor_4,
    s.diff_sensor_11,
    s.diff_sensor_15,
    CASE 
        WHEN r.rul < 10 THEN 'FALLA INMINENTE'
        WHEN r.rul BETWEEN 10 AND 20 THEN 'ALTO RIESGO'
        ELSE 'ESTABLE' 
    END AS estado_motor
FROM rul_data r
JOIN sensor_data s 
    ON r.motor_id = s.motor_id 
    AND r.time_in_cycles = s.time_in_cycles;

SELECT * FROM vulcan_dashboard;




