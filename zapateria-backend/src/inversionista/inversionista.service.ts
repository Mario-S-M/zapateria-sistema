import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Inversionista } from '../entities/inversionista.entity';
import {
  CreateInversionistaDto,
  UpdateInversionistaDto,
} from '../dto/inversionista.dto';

@Injectable()
export class InversionistaService {
  constructor(
    @InjectRepository(Inversionista)
    private inversionistaRepository: Repository<Inversionista>,
  ) {}

  async findAll(): Promise<Inversionista[]> {
    return this.inversionistaRepository.find({
      order: { nombre: 'ASC' },
    });
  }

  async findActivos(): Promise<Inversionista[]> {
    return this.inversionistaRepository.find({
      where: { activo: true },
      order: { nombre: 'ASC' },
    });
  }

  async findOne(id: string): Promise<Inversionista | null> {
    return this.inversionistaRepository.findOne({
      where: { id },
    });
  }

  async create(
    createInversionistaDto: CreateInversionistaDto,
  ): Promise<Inversionista> {
    const inversionista = this.inversionistaRepository.create({
      ...createInversionistaDto,
      activo: createInversionistaDto.activo ?? true,
    });
    return this.inversionistaRepository.save(inversionista);
  }

  async update(
    id: string,
    updateInversionistaDto: UpdateInversionistaDto,
  ): Promise<Inversionista | null> {
    await this.inversionistaRepository.update(id, updateInversionistaDto);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.inversionistaRepository.delete(id);
  }
}
