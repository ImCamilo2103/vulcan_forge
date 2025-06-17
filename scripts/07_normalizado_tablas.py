import hidden1
import psycopg2
from psycopg2.extras import execute_values

# Conexión a la base de datos
secrets = hidden1.secrets()
conn = psycopg2.connect(host = secrets['host'],
                        port = secrets['port'],
                        database = secrets['database'],
                        user = secrets['user'],
                        password = secrets['pass'])
cur = conn.cursor()

# Dataset list
datasets = [
    ('FD001', 'train'),
    ('FD001', 'test'),
    ('FD002', 'train'),
    ('FD002', 'test'),
    ('FD003', 'train'),
    ('FD003', 'test'),
    ('FD004', 'train'),
    ('FD004', 'test')
]

for name, tipo in datasets:
    print(f"\n⚡ Procesando {tipo}_{name} ...")
    
    raw_table = f'"{tipo}_{name}_raw"'
    
    # Insertar motores
    cur.execute(f'''
        INSERT INTO motors (original_id, dataset_id, type)
        SELECT DISTINCT unit_number, 
               (SELECT id FROM datasets WHERE name = %s),
               %s
        FROM {raw_table};
    ''', (name, tipo))
    print("   ✅ Motores insertados")

    # Insertar ciclos
    cur.execute(f'''
        INSERT INTO cycles (motor_id, time_in_cycles, op_setting1, op_setting2, op_setting3)
        SELECT m.id, r.time_in_cycles, r.operational_setting1, r.operational_setting2, r.operational_setting3
        FROM {raw_table} r
        JOIN motors m ON m.original_id = r.unit_number 
                     AND m.dataset_id = (SELECT id FROM datasets WHERE name = %s)
                     AND m.type = %s;
    ''', (name, tipo))
    print("   ✅ Ciclos insertados")

    # Insertar sensores
    cur.execute(f'''
        INSERT INTO sensor_measurements (
            cycle_id, sensor_1, sensor_2, sensor_3, sensor_4, sensor_5, 
            sensor_6, sensor_7, sensor_8, sensor_9, sensor_10, sensor_11, 
            sensor_12, sensor_13, sensor_14, sensor_15, sensor_16, sensor_17, 
            sensor_18, sensor_19, sensor_20, sensor_21
        )
        SELECT c.id, r.sensor_measurement1, r.sensor_measurement2, r.sensor_measurement3, r.sensor_measurement4,
               r.sensor_measurement5, r.sensor_measurement6, r.sensor_measurement7, r.sensor_measurement8, r.sensor_measurement9,
               r.sensor_measurement10, r.sensor_measurement11, r.sensor_measurement12, r.sensor_measurement13, r.sensor_measurement14,
               r.sensor_measurement15, r.sensor_measurement16, r.sensor_measurement17, r.sensor_measurement18, r.sensor_measurement19,
               r.sensor_measurement20, r.sensor_measurement21
        FROM {raw_table} r
        JOIN motors m ON m.original_id = r.unit_number 
                     AND m.dataset_id = (SELECT id FROM datasets WHERE name = %s)
                     AND m.type = %s
        JOIN cycles c ON c.motor_id = m.id AND c.time_in_cycles = r.time_in_cycles;
    ''', (name, tipo))
    print("   ✅ Mediciones insertadas")

    conn.commit()

# Insertar RUL
for name in ['FD001', 'FD002', 'FD003', 'FD004']:
    rul_table = f'"RUL_{name}"'
    print(f"\n📊 Insertando RUL para {name} ...")
    cur.execute(f'ALTER TABLE {rul_table} ADD COLUMN temp_id SERIAL')
    cur.execute(f'''
        INSERT INTO rul (motor_id, rul_value)
        SELECT m.id, r.rul
        FROM {rul_table} r
        JOIN motors m ON m.original_id = r.temp_id
                     AND m.dataset_id = (SELECT id FROM datasets WHERE name = %s)
                     AND m.type = 'test';
    ''', (name,))
    cur.execute(f'ALTER TABLE {rul_table} DROP COLUMN temp_id')
    print("   ✅ RUL insertado")
    conn.commit()

cur.close()
conn.close()
print("\n🚀 MIGRACIÓN FINALIZADA CON ÉXITO")