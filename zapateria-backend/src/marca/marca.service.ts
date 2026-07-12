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

    return this.marcaRepository.save(marca);
  }

  async update(id: string, updateMarcaDto: UpdateMarcaDto): Promise<Marca> {
    const marca = await this.findOne(id);
    const { patronSegmentos, ...marcaData } = updateMarcaDto;

    Object.assign(marca, marcaData);

    if (patronSegmentos !== undefined) {
      Object.assign(marca, this.buildPatronFields(patronSegmentos));
    }

    return this.marcaRepository.save(marca);
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
