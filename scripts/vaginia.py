import psycopg2
import hidden1

# Configuración simple
print("🔧 Iniciando verificación de unit_number...")
print("Objetivo: Confirmar que los números de motor son consistentes con el README\n")

# Conexión a la base de datos
secrets = hidden1.secrets()
conn = psycopg2.connect(
    host=secrets['host'],
    port=secrets['port'],
    database=secrets['database'],
    user=secrets['user'],
    password=secrets['pass']
)
cur = conn.cursor()

# Función para verificación clara
def verificar_unit_numbers(dataset):
    print(f"📋 Dataset {dataset}:")
    
    # 1. Consultar unit_numbers en train
    cur.execute(f"SELECT DISTINCT unit_number FROM train_{dataset} ORDER BY unit_number")
    train_units = [row[0] for row in cur.fetchall()]
    
    # 2. Consultar unit_numbers en test
    cur.execute(f"SELECT DISTINCT unit_number FROM test_{dataset} ORDER BY unit_number")
    test_units = [row[0] for row in cur.fetchall()]
    
    # 3. Verificar según README
    expected_train = 100 if dataset == 'FD001' or dataset == 'FD003' else 260 if dataset == 'FD002' else 248
    expected_test = 100 if dataset == 'FD001' or dataset == 'FD003' else 259 if dataset == 'FD002' else 249
    
    print(f"  - Motores en train: {len(train_units)} (esperados: {expected_train})")
    print(f"  - Motores en test:  {len(test_units)} (esperados: {expected_test})")
    
    # 4. Verificar si hay solapamiento
    overlap = set(train_units) & set(test_units)
    if overlap:
        print(f"  ⚠️ PROBLEMA: {len(overlap)} motores repetidos entre train y test")
        print(f"    Motores repetidos: {sorted(overlap)[:5]}...")  # Muestra solo primeros 5
    else:
        print("  ✅ CORRECTO: Cero motores repetidos entre train y test")
    
    # 5. Verificar secuencia esperada
    print("\n  Primeros 5 motores en cada conjunto:")
    print(f"  - Train: {train_units[:5]}")
    print(f"  - Test:  {test_units[:5]}")
    
    # 6. Verificar si los números son consecutivos
    train_consecutivos = all(train_units[i] + 1 == train_units[i+1] for i in range(len(train_units)-1))
    test_consecutivos = all(test_units[i] + 1 == test_units[i+1] for i in range(len(test_units)-1))
    
    print("\n  Secuencia de motores:")
    print(f"  - Train: {'consecutivos' if train_consecutivos else 'NO consecutivos'}")
    print(f"  - Test:  {'consecutivos' if test_consecutivos else 'NO consecutivos'}")
    print("-" * 50)

# Verificar todos los datasets
for dataset in ['FD001', 'FD002', 'FD003', 'FD004']:
    verificar_unit_numbers(dataset)

# Cerrar conexión
cur.close()
conn.close()

print("\n✅ Verificación completada. Revisa los resultados arriba.")
print("Conclusiones importantes:")
print("- Los motores DEBEN ser diferentes entre train y test para el mismo dataset")
print("- La cantidad DEBE coincidir con lo indicado en el README")
print("- La secuencia puede variar pero no afecta el análisis")