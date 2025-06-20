DROP VIEW IF EXISTS vulcan_dashboard;

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
        CASE 
            WHEN (ml.total_cycles - c.time_in_cycles) < 20 THEN 1 
            ELSE 0 
        END AS critico,
        c.op_setting1,
        c.op_setting2,
        c.op_setting3
    FROM cycles c
    JOIN motors m ON c.motor_id = m.id
    JOIN datasets d ON m.dataset_id = d.id
    JOIN motor_life ml ON m.id = ml.motor_id
    WHERE (ml.total_cycles - c.time_in_cycles) <= 130
),
sensor_data AS (
    SELECT 
        m.original_id AS motor_id,
        c.time_in_cycles,
        s.sensor_4,
        s.sensor_11,
        s.sensor_15,
        s.sensor_4 - LAG(s.sensor_4) OVER (PARTITION BY m.original_id ORDER BY c.time_in_cycles) AS diff_sensor_4,
        s.sensor_11 - LAG(s.sensor_11) OVER (PARTITION BY m.original_id ORDER BY c.time_in_cycles) AS diff_sensor_11,
        s.sensor_15 - LAG(s.sensor_15) OVER (PARTITION BY m.original_id ORDER BY c.time_in_cycles) AS diff_sensor_15
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