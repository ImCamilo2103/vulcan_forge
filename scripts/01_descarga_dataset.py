import os
import csv
import requests
from bs4 import BeautifulSoup
from urllib.parse import unquote

# URL del sitio
url = 'https://www.nasa.gov/intelligent-systems-division/discovery-and-systems-health/pcoe/pcoe-data-set-repository'
response = requests.get(url)
print('📡 Estado de la respuesta:', response)

html = response.text
soup = BeautifulSoup(html, 'html.parser')

# Directorios
page_path = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/raw/page.html'
csv_path = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/raw/links.csv'
output_dir = 'C:/Users/Asus/Documents/data analysis/Portafolio/vulcan_forge/data/raw'
os.makedirs(output_dir, exist_ok=True)

# Guardar página HTML
with open(page_path, 'w', encoding='utf-8') as page:
    page.write(soup.prettify())

# Buscar enlaces .zip
tags = soup.find_all('a', href=True)
enlaces = []
for tag in tags:
    text = tag.get_text(strip=True)
    href = tag['href']
    if href.endswith('.zip') and "turbofan" in href.lower():
        enlaces.append((text, href))

# Guardar links
with open(csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['Texto', 'Enlace'])
    writer.writerows(enlaces)

print(f"🗄️ Se guardaron {len(enlaces)} enlaces en links.csv")

# Descargar archivos
with open(csv_path, encoding='utf-8') as fr:
    reader = csv.reader(fr)
    next(reader)  # Saltar encabezado
    for text, url in reader:
        filename = unquote(url.split('/')[-1]).strip()
        file_path = os.path.join(output_dir, filename)
        print(f"⬇️ Descargando: {filename}")
        try:
            r = requests.get(url, stream=True)
            r.raise_for_status()
            with open(file_path, 'wb') as f_out:
                for chunk in r.iter_content(8192):
                    f_out.write(chunk)
            print(f"✅ Guardado en: {file_path}\n")
        except Exception as e:
            print(f"✖️ Error al descargar {url}: {e}")