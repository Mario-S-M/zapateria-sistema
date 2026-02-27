import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Zapato } from '../entities/zapato.entity';
import { ZapatoColor } from '../entities/zapato-color.entity';
import { CreateZapatoDto, UpdateZapatoDto } from '../dto/zapato.dto';
import { UploadService } from '../upload/upload.service';

@Injectable()
export class ZapatoService {
  constructor(
    @InjectRepository(Zapato)
    private zapatoRepository: Repository<Zapato>,
    @InjectRepository(ZapatoColor)
    private zapatoColorRepository: Repository<ZapatoColor>,
    private uploadService: UploadService,
  ) {}

  async findAll(): Promise<Zapato[]> {
    return this.zapatoRepository.find({
      relations: ['colores', 'colores.color', 'categoria', 'inversionista'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Zapato | null> {
    return this.zapatoRepository.findOne({
      where: { id },
      relations: ['colores', 'colores.color', 'categoria', 'inversionista'],
    });
  }

  async findByCodigoBarras(codigoBarras: string): Promise<Zapato | null> {
    return this.zapatoRepository.findOne({
      where: { codigoBarras },
      relations: ['colores', 'colores.color', 'categoria', 'inversionista'],
    });
  }

  async create(createZapatoDto: CreateZapatoDto): Promise<Zapato> {
    const { codigoBarras } = createZapatoDto;

    const existingZapato = await this.zapatoRepository.findOne({
      where: { codigoBarras },
    });

    if (existingZapato) {
      throw new BadRequestException('El código de barras ya existe');
    }

    const { colorIds, categoriaId, inversionistaId, ...zapatoData } =
      createZapatoDto;

    const zapato = this.zapatoRepository.create({
      ...zapatoData,
      categoriaId,
      inversionistaId,
    });
    const savedZapato = await this.zapatoRepository.save(zapato);

    if (colorIds && colorIds.length > 0) {
      const zapatoColores = colorIds.map((colorId) =>
        this.zapatoColorRepository.create({
          zapatoId: savedZapato.id,
          colorId,
        }),
      );

      await this.zapatoColorRepository.save(zapatoColores);
    }

    const createdZapato = await this.findOne(savedZapato.id);
    if (!createdZapato) {
      throw new BadRequestException('Error al crear el zapato');
    }
    return createdZapato;
  }

  async update(
    id: string,
    updateZapatoDto: UpdateZapatoDto,
  ): Promise<Zapato | null> {
    const { colorIds, categoriaId, inversionistaId, ...zapatoData } =
      updateZapatoDto;

    const updateData = {
      ...zapatoData,
      ...(categoriaId !== undefined && { categoriaId }),
      ...(inversionistaId !== undefined && { inversionistaId }),
    };

    if (Object.keys(updateData).length > 0) {
      await this.zapatoRepository.update(id, updateData);
    }

    if (colorIds && colorIds.length > 0) {
      await this.zapatoColorRepository.delete({ zapatoId: id });

      const zapatoColores = colorIds.map((colorId) =>
        this.zapatoColorRepository.create({
          zapatoId: id,
          colorId,
        }),
      );

      await this.zapatoColorRepository.save(zapatoColores);
    }

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    try {
      // Obtener el zapato para eliminar la imagen
      const zapato = await this.zapatoRepository.findOne({
        where: { id },
      });

      if (!zapato) {
        throw new NotFoundException(`Zapato con ID ${id} no encontrado`);
      }

      // Las ventas son registros históricos, no impedimos la eliminación del zapato
      // Los VentaItems mantendrán la referencia al zapatoId pero sin la relación activa

      console.log(
        `Eliminando zapato ID: ${id}`,
        zapato.foto ? `con foto: ${zapato.foto}` : 'sin foto',
      );

      // Eliminar relaciones de colores primero
      await this.zapatoColorRepository.delete({ zapatoId: id });
      console.log(`Colores del zapato ${id} eliminados`);

      // Eliminar el zapato de la base de datos
      // La configuración onDelete: 'SET NULL' en VentaItem manejará automáticamente las referencias
      await this.zapatoRepository.delete(id);
      console.log(`Zapato ${id} eliminado de la base de datos`);

      // Luego intentar eliminar la imagen (si falla, no afecta la eliminación del zapato)
      if (zapato.foto) {
        try {
          console.log(`Intentando eliminar imagen: ${zapato.foto}`);
          await this.uploadService.deleteZapatoImage(zapato.foto);
          console.log(`Imagen eliminada exitosamente`);
        } catch (imageError) {
          console.error(
            'Error al eliminar imagen, pero zapato eliminado exitosamente:',
            imageError,
          );
        }
      } else {
        console.log('No hay imagen para eliminar');
      }
    } catch (error) {
      console.error('Error al eliminar zapato:', error);
      throw error;
    }
  }
}
