import { Injectable, BadRequestException } from '@nestjs/common';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs';
import * as path from 'path';

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

  async saveZapatoImage(file: Express.Multer.File): Promise<string> {
    this.validateFile(file);

    const fileExtension = extname(file.originalname).toLowerCase();
    const fileName = `${uuidv4()}${fileExtension}`;
    const filePath = path.join(this.uploadPath, fileName);
    const fullPath = path.join(process.cwd(), filePath);

    try {
      console.log(`[Upload] Intentando guardar imagen en: ${fullPath}`);
      console.log(`[Upload] Tamaño del archivo: ${file.buffer?.length} bytes`);
      console.log(`[Upload] CWD: ${process.cwd()}`);
      
      // Asegurar que el directorio existe
      this.ensureUploadDirectory();
      
      // Guardar archivo
      fs.writeFileSync(fullPath, file.buffer);
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