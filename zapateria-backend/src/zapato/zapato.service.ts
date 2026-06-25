import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Zapato } from '../entities/zapato.entity';
import { ZapatoColor } from '../entities/zapato-color.entity';
import { PrecioRango } from '../entities/precio-rango.entity';
import { Inventario } from '../entities/inventario.entity';
import { VentaItem } from '../entities/venta-item.entity';
import { CreateZapatoDto, UpdateZapatoDto } from '../dto/zapato.dto';
import { UploadService } from '../upload/upload.service';

@Injectable()
export class ZapatoService {
  constructor(
    @InjectRepository(Zapato)
    private zapatoRepository: Repository<Zapato>,
    @InjectRepository(ZapatoColor)
    private zapatoColorRepository: Repository<ZapatoColor>,
    @InjectRepository(PrecioRango)
    private precioRangoRepository: Repository<PrecioRango>,
    @InjectRepository(Inventario)
    private inventarioRepository: Repository<Inventario>,
    @InjectRepository(VentaItem)
    private ventaItemRepository: Repository<VentaItem>,
    private uploadService: UploadService,
  ) {}

  async findAll(): Promise<Zapato[]> {
    return this.zapatoRepository.find({
      relations: ['colores', 'colores.color', 'categoria', 'inversionista', 'precioRangos'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Zapato | null> {
    return this.zapatoRepository.findOne({
      where: { id },
      relations: ['colores', 'colores.color', 'categoria', 'inversionista', 'precioRangos'],
    });
  }

  async findByCodigoBarras(codigoBarras: string): Promise<Zapato | null> {
    return this.zapatoRepository.findOne({
      where: { codigoBarras },
      relations: ['colores', 'colores.color', 'categoria', 'inversionista', 'precioRangos'],
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

    const { colorIds, categoriaId, inversionistaId, precioRangos, ...zapatoData } =
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

    if (precioRangos && precioRangos.length > 0) {
      const rangos = precioRangos.map((r) =>
        this.precioRangoRepository.create({ ...r, zapatoId: savedZapato.id }),
      );
      await this.precioRangoRepository.save(rangos);
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
    const { colorIds, categoriaId, inversionistaId, precioRangos, ...zapatoData } =
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

    if (precioRangos !== undefined) {
      await this.precioRangoRepository.delete({ zapatoId: id });
      if (precioRangos.length > 0) {
        const rangos = precioRangos.map((r) =>
          this.precioRangoRepository.create({ ...r, zapatoId: id }),
        );
        await this.precioRangoRepository.save(rangos);
      }
    }

    return this.findOne(id);
  }

  async merge(originalId: string, duplicateId: string): Promise<Zapato | null> {
    if (originalId === duplicateId) {
      throw new BadRequestException('No puedes unir un zapato consigo mismo');
    }

    const original = await this.zapatoRepository.findOne({ where: { id: originalId } });
    const duplicate = await this.zapatoRepository.findOne({ where: { id: duplicateId } });

    if (!original) throw new NotFoundException(`Zapato original ${originalId} no encontrado`);
    if (!duplicate) throw new NotFoundException(`Zapato duplicado ${duplicateId} no encontrado`);

    // Move inventory: add quantities to original, skip if original already has that combo
    const dupInventario = await this.inventarioRepository.find({
      where: { zapatoId: duplicateId },
    });

    for (const item of dupInventario) {
      const existing = await this.inventarioRepository.findOne({
        where: { zapatoId: originalId, colorId: item.colorId ?? undefined, talla: item.talla },
      });
      if (existing) {
        existing.cantidad += item.cantidad;
        await this.inventarioRepository.save(existing);
      } else {
        await this.inventarioRepository.save(
          this.inventarioRepository.create({
            zapatoId: originalId,
            colorId: item.colorId ?? undefined,
            talla: item.talla,
            cantidad: item.cantidad,
          }),
        );
      }
    }

    // Remap venta items
    await this.ventaItemRepository.update(
      { zapatoId: duplicateId },
      { zapatoId: originalId },
    );

    // Delete duplicate (cascades ZapatoColor and Inventario)
    await this.zapatoColorRepository.delete({ zapatoId: duplicateId });
    await this.inventarioRepository.delete({ zapatoId: duplicateId });
    await this.precioRangoRepository.delete({ zapatoId: duplicateId });
    await this.zapatoRepository.delete(duplicateId);

    // Delete duplicate photos
    const allFotos = [
      ...(duplicate.fotos ?? []),
      ...(duplicate.foto && !(duplicate.fotos ?? []).includes(duplicate.foto) ? [duplicate.foto] : []),
    ];
    for (const fotoPath of allFotos) {
      try { await this.uploadService.deleteZapatoImage(fotoPath); } catch (_) {}
    }

    return this.findOne(originalId);
  }

  async remove(id: string): Promise<void> {
    try {
      const zapato = await this.zapatoRepository.findOne({ where: { id } });

      if (!zapato) {
        throw new NotFoundException(`Zapato con ID ${id} no encontrado`);
      }

      console.log(
        `Eliminando zapato ID: ${id}`,
        zapato.foto ? `con foto: ${zapato.foto}` : 'sin foto',
      );

      await this.zapatoColorRepository.delete({ zapatoId: id });
      await this.precioRangoRepository.delete({ zapatoId: id });
      await this.zapatoRepository.delete(id);

      const allFotos = [
        ...(zapato.fotos ?? []),
        ...(zapato.foto && !(zapato.fotos ?? []).includes(zapato.foto) ? [zapato.foto] : []),
      ];
      for (const fotoPath of allFotos) {
        try {
          await this.uploadService.deleteZapatoImage(fotoPath);
        } catch (_) {}
      }
    } catch (error) {
      console.error('Error al eliminar zapato:', error);
      throw error;
    }
  }
}
