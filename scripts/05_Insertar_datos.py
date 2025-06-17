import hidden1
import os
import pandas as pd
import psycopg2

secrets = hidden1.secrets()
conn = psycopg2.connect(
    host = secrets['host'],
    port = secrets['port'],
    database = secrets['database'],
    user = secrets['user'],
    password = secrets['pass'])

cur = conn.cursor()

clean_dir = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/cleaned'

for file in os.listdir(clean_dir):
    if not file.endswith('.csv'):
        continue

    path = os.path.join(clean_dir, file)
    table = file.replace('.csv', '')
    table_name = f'{table}_raw'

    if table.lower().startswith('rul'):
        df = pd.read_csv(path, header=0, names=['rul'])
        for value in df['rul']:
            cur.execute(f'INSERT INTO "{table}" (rul) VALUES (%s);', (int(value),))
            print(f'🗃️ Insertados {len(df)} valores en {table}')

    else:
        columns = ['unit_number', 'time_in_cycles'] + [f'operational_setting{i}' for i in range(1, 4)] + [f'sensor_measurement{j}' for j in range(1, 22)]
        df = pd.read_csv(path, header=0, names=columns)
        placeholders = ', '.join(['%s'] * len(columns))
        cols= ', '.join(columns)

        for row in df.itertuples(index=False, name=None):
            cur.execute(f'INSERT INTO "{table_name}" ({cols}) VALUES ({placeholders});', row)
        print(f'🗃️ datos insertados {len(df)} valores en {table_name}')

conn.commit()
cur.close()
conn.close()
print("🚀 Todos los datos fueron cargados exitosamente.")