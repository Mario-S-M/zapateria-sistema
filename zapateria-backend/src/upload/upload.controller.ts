import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UploadService } from './upload.service';

@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('zapato-image')
  @UseInterceptors(FileInterceptor('image'))
  async uploadZapatoImage(@UploadedFile() file: Express.Multer.File) {
    console.log(`[Upload Controller] Archivo recibido:`, file ? {
      fieldname: file.fieldname,
      originalname: file.originalname,
      encoding: file.encoding,
      mimetype: file.mimetype,
      size: file.size,
      bufferLength: file.buffer?.length
    } : 'NO RECIBIDO');

    if (!file) {
      throw new BadRequestException('No se ha proporcionado ninguna imagen');
    }

    try {
      const filePath = await this.uploadService.saveZapatoImage(file);
      console.log(`[Upload Controller] Imagen guardada con éxito: ${filePath}`);
      
      return {
        message: 'Imagen subida exitosamente',
        filePath: filePath,
        originalName: file.originalname,
        size: file.size,
      };
    } catch (error) {
      console.error(`[Upload Controller] Error:`, error);
      throw new BadRequestException(error.message || 'Error al subir la imagen');
    }
  }
}