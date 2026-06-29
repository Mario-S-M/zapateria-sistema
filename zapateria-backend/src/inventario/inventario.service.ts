import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { Inventario } from '../entities/inventario.entity';
import { InventarioItemDto } from '../dto/inventario.dto';

@Injectable()
export class InventarioService {
  constructor(
    @InjectRepository(Inventario)
    private readonly repo: Repository<Inventario>,
  ) {}

  async findAll(): Promise<Inventario[]> {
    return this.repo.find();
  }

  async getByZapato(zapatoId: string): Promise<Inventario[]> {
    return this.repo.find({
      where: { zapatoId },
      relations: ['color'],
      order: { colorId: 'ASC', talla: 'ASC' },
    });
  }

  async getStock(zapatoId: string, colorId: string | null, talla: number): Promise<number> {
    const item = await this.repo.findOne({
      where: { zapatoId, colorId: colorId ?? IsNull(), talla },
    });
    return item?.cantidad ?? 0;
  }

  async bulkUpsert(items: InventarioItemDto[]): Promise<void> {
    for (const item of items) {
      const existing = await this.repo.findOne({
        where: {
          zapatoId: item.zapatoId,
          colorId: item.colorId ?? IsNull(),
          talla: item.talla,
        },
      });
      if (existing) {
        existing.cantidad = item.cantidad;
        await this.repo.save(existing);
      } else {
        const newItem = this.repo.create();
        newItem.zapatoId = item.zapatoId;
        newItem.colorId = item.colorId ?? undefined;
        newItem.talla = item.talla;
        newItem.cantidad = item.cantidad;
        await this.repo.save(newItem);
      }
    }
  }

  async decrement(zapatoId: string, colorId: string | null, talla: number, cantidad: number): Promise<void> {
    const item = await this.repo.findOne({
      where: { zapatoId, colorId: colorId ?? IsNull(), talla },
    });
    if (item) {
      item.cantidad = Math.max(0, item.cantidad - cantidad);
      await this.repo.save(item);
    }
  }
}
