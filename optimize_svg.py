#!/usr/bin/env python3
"""
Script para optimizar SVG manteniendo la imagen
Reduce el peso del archivo SVG sin perder calidad visual
"""

import os
import re
import base64
from PIL import Image
from io import BytesIO

def optimize_svg(input_path, output_path=None):
    """
    Optimiza un archivo SVG reduciendo el tamaño de la imagen embebida
    
    Args:
        input_path: Ruta del archivo SVG original
        output_path: Ruta del archivo SVG optimizado (si no se especifica, sobrescribe el original)
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
        print("No se encontró imagen PNG embebida en el SVG")
        return
    
    # Extraer y decodificar la imagen
    base64_data = match.group(1)
    image_data = base64.b64decode(base64_data)
    
    # Abrir la imagen
    img = Image.open(BytesIO(image_data))
    
    print(f"Imagen original: {len(image_data)} bytes ({len(image_data)/1024:.2f} KB)")
    print(f"Dimensiones: {img.size}")
    print(f"Formato: {img.format}")
    
    # Optimizar la imagen
    # Reducir calidad y convertir a RGB si es necesario
    if img.mode == 'RGBA':
        # Crear fondo blanco
        background = Image.new('RGB', img.size, (255, 255, 255))
        background.paste(img, mask=img.split()[3] if len(img.split()) == 4 else None)
        img = background
    elif img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Guardar con compresión optimizada
    optimized_buffer = BytesIO()
    img.save(optimized_buffer, format='PNG', optimize=True, quality=85)
    optimized_data = optimized_buffer.getvalue()
    
    # Codificar a base64
    optimized_base64 = base64.b64encode(optimized_data).decode('utf-8')
    
    # Reemplazar en el SVG
    new_svg_content = svg_content.replace(
        f'data:image/png;base64,{base64_data}',
        f'data:image/png;base64,{optimized_base64}'
    )
    
    # Guardar el SVG optimizado
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(new_svg_content)
    
    print(f"\nImagen optimizada: {len(optimized_data)} bytes ({len(optimized_data)/1024:.2f} KB)")
    print(f"Reducción: {len(image_data) - len(optimized_data)} bytes ({((len(image_data) - len(optimized_data))/len(image_data)*100):.1f}%)")
    print(f"\nSVG guardado en: {output_path}")

if __name__ == "__main__":
    input_file = "assets/icons/pic_transfer.svg"
    
    if os.path.exists(input_file):
        optimize_svg(input_file)
    else:
        print(f"Archivo no encontrado: {input_file}")
