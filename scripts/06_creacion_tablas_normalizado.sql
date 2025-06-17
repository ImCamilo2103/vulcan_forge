-- Eliminar tablas existentes si es necesario
DROP TABLE IF EXISTS sensor_measurements CASCADE;
DROP TABLE IF EXISTS rul CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS motors CASCADE;
DROP TABLE IF EXISTS datasets CASCADE;

-- Tabla de datasets
CREATE TABLE datasets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(10) UNIQUE NOT NULL,
    train_engines INT NOT NULL,
    test_engines INT NOT NULL,
    conditions VARCHAR(50) NOT NULL,
    fault_modes VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE datasets IS 'Almacena metadatos sobre los diferentes conjuntos de datos';
COMMENT ON COLUMN datasets.name IS 'Nombre del dataset (FD001, FD002, etc)';
COMMENT ON COLUMN datasets.train_engines IS 'Número de motores en entrenamiento';
COMMENT ON COLUMN datasets.test_engines IS 'Número de motores en prueba';
COMMENT ON COLUMN datasets.conditions IS 'Condiciones operativas';
COMMENT ON COLUMN datasets.fault_modes IS 'Modos de falla';

-- Tabla de motores
CREATE TABLE motors (
    id SERIAL PRIMARY KEY,
    original_id INT NOT NULL,
    dataset_id INT NOT NULL REFERENCES datasets(id),
    type VARCHAR(5) NOT NULL CHECK (type IN ('train', 'test')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (original_id, dataset_id, type)
);

COMMENT ON TABLE motors IS 'Representa cada motor individual';
COMMENT ON COLUMN motors.original_id IS 'ID original del motor';
COMMENT ON COLUMN motors.dataset_id IS 'Referencia al dataset';
COMMENT ON COLUMN motors.type IS 'Tipo: train o test';

-- Tabla de ciclos operativos
CREATE TABLE cycles (
    id SERIAL PRIMARY KEY,
    motor_id INT NOT NULL REFERENCES motors(id),
    time_in_cycles INT NOT NULL,
    op_setting1 DOUBLE PRECISION NOT NULL,
    op_setting2 DOUBLE PRECISION NOT NULL,
    op_setting3 DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (motor_id, time_in_cycles)
);

COMMENT ON TABLE cycles IS 'Registra cada ciclo operativo de un motor';
COMMENT ON COLUMN cycles.motor_id IS 'Referencia al motor';
COMMENT ON COLUMN cycles.time_in_cycles IS 'Tiempo en ciclos';
COMMENT ON COLUMN cycles.op_setting1 IS 'Configuración operativa 1';
COMMENT ON COLUMN cycles.op_setting2 IS 'Configuración operativa 2';
COMMENT ON COLUMN cycles.op_setting3 IS 'Configuración operativa 3';

-- Tabla de mediciones de sensores
CREATE TABLE sensor_measurements (
    cycle_id INT PRIMARY KEY REFERENCES cycles(id),
    sensor_1 DOUBLE PRECISION NOT NULL,
    sensor_2 DOUBLE PRECISION NOT NULL,
    sensor_3 DOUBLE PRECISION NOT NULL,
    sensor_4 DOUBLE PRECISION NOT NULL,
    sensor_5 DOUBLE PRECISION NOT NULL,
    sensor_6 DOUBLE PRECISION NOT NULL,
    sensor_7 DOUBLE PRECISION NOT NULL,
    sensor_8 DOUBLE PRECISION NOT NULL,
    sensor_9 DOUBLE PRECISION NOT NULL,
    sensor_10 DOUBLE PRECISION NOT NULL,
    sensor_11 DOUBLE PRECISION NOT NULL,
    sensor_12 DOUBLE PRECISION NOT NULL,
    sensor_13 DOUBLE PRECISION NOT NULL,
    sensor_14 DOUBLE PRECISION NOT NULL,
    sensor_15 DOUBLE PRECISION NOT NULL,
    sensor_16 DOUBLE PRECISION NOT NULL,
    sensor_17 DOUBLE PRECISION NOT NULL,
    sensor_18 DOUBLE PRECISION NOT NULL,
    sensor_19 DOUBLE PRECISION NOT NULL,
    sensor_20 DOUBLE PRECISION NOT NULL,
    sensor_21 DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE sensor_measurements IS 'Almacena las mediciones de los sensores para un ciclo específico';
COMMENT ON COLUMN sensor_measurements.cycle_id IS 'Referencia al ciclo operativo';

-- Tabla RUL
CREATE TABLE rul (
    motor_id INT PRIMARY KEY REFERENCES motors(id),
    rul_value INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE rul IS 'Contiene el Remaining Useful Life para cada motor de prueba';
COMMENT ON COLUMN rul.motor_id IS 'Referencia al motor';
COMMENT ON COLUMN rul.rul_value IS 'Valor RUL (Remaining Useful Life)';

-- Índices para optimización
CREATE INDEX idx_motors_dataset ON motors(dataset_id);
CREATE INDEX idx_motors_type ON motors(type);
CREATE INDEX idx_cycles_motor ON cycles(motor_id);
CREATE INDEX idx_cycles_time ON cycles(time_in_cycles);
CREATE INDEX idx_rul_value ON rul(rul_value);

-- Insertar datos de los datasets según README
INSERT INTO datasets (name, train_engines, test_engines, conditions, fault_modes)
VALUES 
    ('FD001', 100, 100, 'ONE (Sea Level)', 'ONE (HPC Degradation)'),
    ('FD002', 260, 259, 'SIX', 'ONE (HPC Degradation)'),
    ('FD003', 100, 100, 'ONE (Sea Level)', 'TWO (HPC Degradation, Fan Degradation)'),
    ('FD004', 248, 249, 'SIX', 'TWO (HPC Degradation, Fan Degradation)');