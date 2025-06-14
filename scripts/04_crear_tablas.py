import os
import hidden1
import psycopg2

secrets = hidden1.secrets()
conn = psycopg2.connect(host = secrets['host'],
                        port = secrets['port'],
                        database = secrets['database'],
                        user = secrets['user'],
                        password = secrets['pass'],
                        connect_timeout = 3)

clean_dir = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/cleaned'
columns = [('unit_number', 'INTEGER'), ('time, in_cycles', 'INTEGER')] + [(f'operational_setting{i}', 'FLOAT') for i in range(1, 4)] + [(f'sensor_measuremet{e}', 'FLOAT') for e in range(1, 22)]
columns_sql = ', '.join([f'"{col}" {col_type}' for col, col_type in columns])

for file in os.listdir(clean_dir):
    fname = file.rstrip('.csv')
    cur = conn.cursor()

    if fname.startswith('RUL'):
        sql = f'DROP TABLE IF EXISTS "{fname}";'
        cur.execute(sql)
        
        sql = f'CREATE TABLE "{fname}"(rul INTEGER);'
        cur.execute(sql)
        print(f'🪧 Se creo la tabla "{fname}"')

    else:
        sql = f'DROP TABLE IF EXISTS "{fname}"'
        cur.execute(sql)

        sql = f'CREATE TABLE "{fname}"({columns_sql});'
        cur.execute(sql)
        print(f'🪧 Se creo la tabla "{fname}"')
    
conn.commit()