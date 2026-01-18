from PIL import Image
import os

png_path = r"assets\trazos\trazo_contrasena2.png"
svg_path = r"assets\trazos\trazo_contrasena2.svg"

# Abrir imagen
img = Image.open(png_path)
width, height = img.size

# Convertir a escala de grises y luego a blanco y negro
img = img.convert('L')
img = img.point(lambda x: 0 if x < 128 else 255, '1')

# Obtener píxeles
pixels = img.load()

# Crear SVG
svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg">
  <rect width="{width}" height="{height}" fill="white"/>
'''

# Convertir píxeles a rectángulos SVG
for y in range(height):
    for x in range(width):
        if pixels[x, y] == 0:  # Píxeles negros
            svg_content += f'  <rect x="{x}" y="{y}" width="1" height="1" fill="black"/>\n'

svg_content += '</svg>'

# Guardar SVG
with open(svg_path, 'w') as f:
    f.write(svg_content)

print(f"✓ Conversión exitosa: {svg_path}")
