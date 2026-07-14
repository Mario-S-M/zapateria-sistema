import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Categoria } from '../entities/categoria.entity';
import { CreateCategoriaDto, UpdateCategoriaDto } from '../dto/categoria.dto';

@Injectable()
export class CategoriaService {
  constructor(
    @InjectRepository(Categoria)
    private categoriaRepository: Repository<Categoria>,
  ) {}

  async findAll(): Promise<Categoria[]> {
    return this.categoriaRepository.find({
      where: { activo: true },
      order: { nombre: 'ASC' },
    });
  }

  async findOne(id: string): Promise<Categoria> {
    const categoria = await this.categoriaRepository.findOne({
      where: { id },
      relations: ['zapatos'],
    });
    
    if (!categoria) {
      throw new NotFoundException(`Categoría con ID ${id} no encontrada`);
    }
    
    return categoria;
  }

  async create(createCategoriaDto: CreateCategoriaDto): Promise<Categoria> {
    const categoria = this.categoriaRepository.create({
      nombre: createCategoriaDto.nombre,
      activo: createCategoriaDto.activo ?? true,
    });

    return this.categoriaRepository.save(categoria);
  }

  async update(id: string, updateCategoriaDto: UpdateCategoriaDto): Promise<Categoria> {
    const categoria = await this.findOne(id);

    // Los campos opcionales del DTO quedan como `undefined` explícito (no
    // ausentes) por las semánticas de class fields de TS; Object.assign sí
    // copia claves `undefined`, así que hay que filtrarlas para no borrar
    // valores ya cargados de la entidad cuando el cliente no los envía.
    for (const [key, value] of Object.entries(updateCategoriaDto)) {
      if (value !== undefined) {
        (categoria as unknown as Record<string, unknown>)[key] = value;
      }
    }

    return this.categoriaRepository.save(categoria);
  }

  async remove(id: string): Promise<void> {
    const categoria = await this.findOne(id);
    
    // Soft delete - just mark as inactive
    categoria.activo = false;
    await this.categoriaRepository.save(categoria);
  }
}