import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Not, IsNull, Repository } from 'typeorm';
import { BarcodeSegmento, Marca } from '../entities/marca.entity';
import { CreateMarcaDto, UpdateMarcaDto } from '../dto/marca.dto';

@Injectable()
export class MarcaService {
  constructor(
    @InjectRepository(Marca)
    private marcaRepository: Repository<Marca>,
  ) {}

  async findAll(): Promise<Marca[]> {
    return this.marcaRepository.find({
      order: { nombre: 'ASC' },
    });
  }

  async findOne(id: string): Promise<Marca> {
    const marca = await this.marcaRepository.findOne({ where: { id } });

    if (!marca) {
      throw new NotFoundException(`Marca con ID ${id} no encontrada`);
    }

    return marca;
  }

  async findConPatronPorLongitud(longitud: number): Promise<Marca[]> {
    return this.marcaRepository.find({
      where: {
        activo: true,
        patronLongitud: longitud,
        patronSegmentos: Not(IsNull()),
      },
    });
  }

  async create(createMarcaDto: CreateMarcaDto): Promise<Marca> {
    const { patronSegmentos, ...marcaData } = createMarcaDto;

    const marca = this.marcaRepository.create({
      ...marcaData,
      activo: createMarcaDto.activo ?? true,
      ...this.buildPatronFields(patronSegmentos),
    });

    try {
      return await this.marcaRepository.save(marca);
    } catch (error) {
      this.handleUniqueConstraintError(error);
    }
  }

  async update(id: string, updateMarcaDto: UpdateMarcaDto): Promise<Marca> {
    const marca = await this.findOne(id);
    const { patronSegmentos, ...marcaData } = updateMarcaDto;

    // Los campos opcionales del DTO quedan como `undefined` explícito (no
    // ausentes) por las semánticas de class fields de TS; Object.assign sí
    // copia claves `undefined`, así que hay que filtrarlas para no borrar
    // valores ya cargados de la entidad cuando el cliente no los envía.
    for (const [key, value] of Object.entries(marcaData)) {
      if (value !== undefined) {
        (marca as unknown as Record<string, unknown>)[key] = value;
      }
    }

    if (patronSegmentos !== undefined) {
      Object.assign(marca, this.buildPatronFields(patronSegmentos));
    }

    try {
      return await this.marcaRepository.save(marca);
    } catch (error) {
      this.handleUniqueConstraintError(error);
    }
  }

  private handleUniqueConstraintError(error: unknown): never {
    if (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: string }).code === '23505'
    ) {
      throw new BadRequestException('Ya existe una marca con ese nombre');
    }
    throw error;
  }

  async remove(id: string): Promise<void> {
    const marca = await this.findOne(id);

    // Soft delete - just mark as inactive
    marca.activo = false;
    await this.marcaRepository.save(marca);
  }

  private buildPatronFields(
    patronSegmentos: BarcodeSegmento[] | undefined,
  ): Pick<Marca, 'patronSegmentos' | 'patronLongitud'> {
    if (!patronSegmentos || patronSegmentos.length === 0) {
      return { patronSegmentos: null, patronLongitud: undefined };
    }

    this.validarPatron(patronSegmentos);

    return {
      patronSegmentos,
      patronLongitud: patronSegmentos.reduce((sum, s) => sum + s.longitud, 0),
    };
  }

  private validarPatron(segmentos: BarcodeSegmento[]): void {
    const ordenados = [...segmentos].sort((a, b) => a.inicio - b.inicio);

    if (ordenados[0].inicio !== 0) {
      throw new BadRequestException('El patrón debe comenzar en la posición 0');
    }

    for (let i = 0; i < ordenados.length - 1; i++) {
      const actual = ordenados[i];
      const siguiente = ordenados[i + 1];
      if (siguiente.inicio !== actual.inicio + actual.longitud) {
        throw new BadRequestException(
          'Los segmentos del patrón deben ser contiguos, sin huecos ni superposiciones',
        );
      }
    }

    const segmentosTalla = ordenados.filter((s) => s.tipo === 'talla');
    if (segmentosTalla.length !== 1) {
      throw new BadRequestException(
        'El patrón debe tener exactamente un segmento de talla',
      );
    }
    if (ordenados[ordenados.length - 1].tipo !== 'talla') {
      throw new BadRequestException(
        'El segmento de talla debe ser el último del patrón',
      );
    }

    const tieneIdentificador = ordenados.some(
      (s) => s.tipo === 'fijo' || s.tipo === 'modelo',
    );
    if (!tieneIdentificador) {
      throw new BadRequestException(
        'El patrón debe tener al menos un segmento fijo o de modelo para identificar el calzado',
      );
    }
  }
}
