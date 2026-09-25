import { Injectable, BadRequestException } from '@nestjs/common';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs';
import * as path from 'path';
import sharp from 'sharp';

@Injectable()
export class UploadService {
  private readonly uploadPath = 'uploads/zapatos';
  private readonly allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
  private readonly maxFileSize = 5 * 1024 * 1024; // 5MB

  constructor() {
    // Crear directorio si no existe
    this.ensureUploadDirectory();
  }

  private ensureUploadDirectory(): void {
    const fullPath = path.join(process.cwd(), this.uploadPath);
    if (!fs.existsSync(fullPath)) {
      fs.mkdirSync(fullPath, { recursive: true });
    }
  }

  // Lado más largo al que se redimensiona toda foto subida. Una foto de
  // cámara/celular sin procesar puede pesar varios MB a resolución completa;
  // en la app nunca se muestra más grande que una tarjeta o el lightbox, así
  // que no hay razón para servir (ni para que el cliente descargue) más de
  // esto. Baja el peso típico de MBs a cientos de KB.
  private readonly maxDimension = 1600;
  private readonly jpegQuality = 82;

  async saveZapatoImage(file: Express.Multer.File): Promise<string> {
    this.validateFile(file);

    // Siempre se guarda como .jpg: reencodear a un formato/calidad
    // consistente es lo que realmente baja el peso, sin importar el
    // formato de origen (jpg/png/webp).
    const fileName = `${uuidv4()}.jpg`;
    const filePath = path.join(this.uploadPath, fileName);
    const fullPath = path.join(process.cwd(), filePath);

    try {
      console.log(`[Upload] Tamaño original: ${file.buffer?.length} bytes`);

      const processed = await sharp(file.buffer)
        .rotate() // aplica la orientación EXIF antes de descartar metadata
        .resize({
          width: this.maxDimension,
          height: this.maxDimension,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .jpeg({ quality: this.jpegQuality })
        .toBuffer();

      console.log(`[Upload] Tamaño tras redimensionar/comprimir: ${processed.length} bytes`);

      this.ensureUploadDirectory();
      fs.writeFileSync(fullPath, processed);
      console.log(`[Upload] Imagen guardada exitosamente: ${fullPath}`);

      // Retornar path relativo para la base de datos
      return filePath.replace(/\\/g, '/'); // Normalizar separadores para diferentes OS
    } catch (error) {
      console.error(`[Upload] Error al guardar imagen:`, error);
      throw new BadRequestException(`Error al guardar la imagen: ${error.message}`);
    }
  }

  async deleteZapatoImage(filePath: string): Promise<void> {
    try {
      // Si el filePath es una URL completa, extraer solo el nombre del archivo
      let fileName = filePath;
      if (filePath.includes('/uploads/')) {
        fileName = filePath.split('/uploads/')[1];
      }
      
      const fullPath = path.join(process.cwd(), this.uploadPath, fileName);
      
      // Verificar si el archivo existe antes de intentar eliminarlo
      if (fs.existsSync(fullPath)) {
        fs.unlinkSync(fullPath);
        console.log(`Imagen eliminada: ${fullPath}`);
      } else {
        console.log(`Archivo no encontrado, no se puede eliminar: ${fullPath}`);
      }
    } catch (error) {
      // No lanzar error, solo logear - la eliminación de la imagen no debe bloquear la eliminación del zapato
      console.error('Error al eliminar imagen:', error);
    }
  }

  private validateFile(file: Express.Multer.File): void {
    if (!file) {
      throw new BadRequestException('No se ha proporcionado ningún archivo');
    }

    if (file.size > this.maxFileSize) {
      throw new BadRequestException('El archivo es demasiado grande (máximo 5MB)');
    }

    const fileExtension = extname(file.originalname).toLowerCase();
    if (!this.allowedExtensions.includes(fileExtension)) {
      throw new BadRequestException(
        `Extensión de archivo no permitida. Permitidas: ${this.allowedExtensions.join(', ')}`
      );
    }

    // Validar que sea realmente una imagen por su MIME type
    const allowedMimeTypes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/webp'
    ];

    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException('El archivo debe ser una imagen válida');
    }
  }
}