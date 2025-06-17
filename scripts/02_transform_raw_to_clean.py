import os
import pandas as pd

raw_dir = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/raw'
clean_dir = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/cleaned'
os.makedirs(clean_dir, exist_ok=True)

columns = ['unit_number', 'time_in_cicles'] + [f'operational_setting{i}' for i in range(1, 4)] + [f'sensor_measurement{e}' for e in range(1, 22)]

for file in os.listdir(raw_dir):
    if file.endswith('.txt') and file != 'readme.txt':
        file_path = os.path.join(raw_dir, file)
        if file.startswith('RUL'):
               fname= file.rstrip('.txt')
               df = pd.read_csv(file_path, header=None, names=['rul'], delim_whitespace=True)
               output_path = os.path.join(clean_dir, f'{fname}.csv')
               df.to_csv(output_path, index=False)
        else:
             fname = file.rstrip('.txt')
             df = pd.read_csv(file_path, header=None, names=columns, delim_whitespace=True)
             output_path = os.path.join(clean_dir, f'{fname}.csv')
             df.to_csv(output_path, index=False)
        print(f"✅ {file} ➡️ {fname}.csv guardado en {output_path}")       

for file in os.listdir(clean_dir):
    file_path = os.path.join(clean_dir, file)
    try:
        if not file.startswith('rul'):
            df = pd.read_csv(file_path)
            for col in df.columns:
                if df[col].dtype == 'object':
                    try:
                        pd.to_numeric(df[col], errors='raise')
                    except Exception as e:
                        print(f"❌ Error en columna '{col}' del archivo '{file}': {e}")
                        print("👀 Valores problemáticos:")
                        print(df[col].unique()[:10])
    except Exception as e:
        print(f"💥 Error cargando {file}: {e}")