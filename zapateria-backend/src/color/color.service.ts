import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Color } from '../entities/color.entity';
import { CreateColorDto, UpdateColorDto } from '../dto/color.dto';

@Injectable()
export class ColorService {
  constructor(
    @InjectRepository(Color)
    private colorRepository: Repository<Color>,
  ) {}

  async findAll(): Promise<Color[]> {
    return this.colorRepository.find({
      order: { nombre: 'ASC' },
    });
  }

  async findOne(id: string): Promise<Color | null> {
    return this.colorRepository.findOne({
      where: { id },
      relations: ['zapatos'],
    });
  }

  async create(createColorDto: CreateColorDto): Promise<Color> {
    try {
      // Verificar si ya existe un color con el mismo nombre
      const existingColor = await this.colorRepository.findOne({
        where: { nombre: createColorDto.nombre },
      });

      if (existingColor) {
        throw new BadRequestException(`El color "${createColorDto.nombre}" ya existe`);
      }

      const color = this.colorRepository.create(createColorDto);
      return await this.colorRepository.save(color);
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Error al crear el color: ${error.message}`);
    }
  }

  async update(id: string, updateColorDto: UpdateColorDto): Promise<Color | null> {
    try {
      // Si se va a actualizar el nombre, verificar que no exista otro color con ese nombre
      if (updateColorDto.nombre) {
        const existingColor = await this.colorRepository.findOne({
          where: { nombre: updateColorDto.nombre },
        });

        if (existingColor && existingColor.id !== id) {
          throw new BadRequestException(`El color "${updateColorDto.nombre}" ya existe`);
        }
      }

      await this.colorRepository.update(id, updateColorDto);
      return this.findOne(id);
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Error al actualizar el color: ${error.message}`);
    }
  }

  async remove(id: string): Promise<void> {
    await this.colorRepository.delete(id);
  }
}
