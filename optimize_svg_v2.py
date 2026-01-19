#!/usr/bin/env python3
"""
Script para optimizar SVG con compresión más agresiva
"""

import os
import re
import base64
from PIL import Image
from io import BytesIO

def optimize_svg_aggressive(input_path, output_path=None, quality=70, scale=0.8):
    """
    Optimiza un SVG con compresión más agresiva
    
    Args:
        input_path: Ruta del archivo SVG original
        output_path: Ruta del archivo SVG optimizado
        quality: Calidad JPEG (1-100)
        scale: Factor de escala (0.8 = 80% del tamaño original)
    """
    
    if output_path is None:
        output_path = input_path
    
    # Leer el archivo SVG
    with open(input_path, 'r', encoding='utf-8') as f:
        svg_content = f.read()
    
    # Buscar la imagen base64 embebida
    pattern = r'data:image/png;base64,([A-Za-z0-9+/=]+)'
    match = re.search(pattern, svg_content)
    
    if not match:
        print("No se encontró imagen PNG embebida")
        return
    
    # Extraer y decodificar
    base64_data = match.group(1)
    image_data = base64.b64decode(base64_data)
    
    # Abrir imagen
    img = Image.open(BytesIO(image_data))
    
    print(f"Original: {len(image_data)} bytes ({len(image_data)/1024:.2f} KB)")
    print(f"Dimensiones: {img.size}")
    
    # Redimensionar
    new_size = (int(img.width * scale), int(img.height * scale))
    img = img.resize(new_size, Image.Resampling.LANCZOS)
    
    # Convertir a RGB
    if img.mode != 'RGB':
        if img.mode == 'RGBA':
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[3])
            img = background
        else:
            img = img.convert('RGB')
    
    # Guardar como JPEG (mejor compresión)
    optimized_buffer = BytesIO()
    img.save(optimized_buffer, format='JPEG', quality=quality, optimize=True)
    optimized_data = optimized_buffer.getvalue()
    
    # Codificar a base64
    optimized_base64 = base64.b64encode(optimized_data).decode('utf-8')
    
    # Reemplazar en SVG
    new_svg_content = svg_content.replace(
        f'data:image/png;base64,{base64_data}',
        f'data:image/jpeg;base64,{optimized_base64}'
    )
    
    # Guardar
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(new_svg_content)
    
    print(f"Optimizado: {len(optimized_data)} bytes ({len(optimized_data)/1024:.2f} KB)")
    print(f"Reducción: {((len(image_data) - len(optimized_data))/len(image_data)*100):.1f}%")
    print(f"Guardado en: {output_path}")

if __name__ == "__main__":
    input_file = "assets/icons/pic_transfer.svg"
    
    if os.path.exists(input_file):
        # Versión agresiva: JPEG con calidad 70 y escala 0.8
        optimize_svg_aggressive(input_file, quality=70, scale=0.8)
    else:
        print(f"Archivo no encontrado: {input_file}")
