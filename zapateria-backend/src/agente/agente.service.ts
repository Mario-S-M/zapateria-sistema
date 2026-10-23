import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Inventario } from '../entities/inventario.entity';
import { PrecioRango } from '../entities/precio-rango.entity';
import { Categoria } from '../entities/categoria.entity';
import { Color } from '../entities/color.entity';

export interface VarianteTalla {
  colorId: string | null;
  color: string | null;
  cantidad: number;
}

export interface ItemInventarioTalla {
  zapatoId: string;
  nombre: string;
  modelo: string;
  foto: string;
  categoriaId: string | null;
  categoria: string | null;
  precioPublico: number;
  variantes: VarianteTalla[];
}

export interface InventarioTallaResponse {
  talla: number;
  items: ItemInventarioTalla[];
}

export interface FiltroInventarioTalla {
  categoriaId?: string;
  colorId?: string;
}

@Injectable()
export class AgenteService {
  constructor(
    @InjectRepository(Inventario)
    private readonly inventarioRepository: Repository<Inventario>,
    @InjectRepository(Categoria)
    private readonly categoriaRepository: Repository<Categoria>,
    @InjectRepository(Color)
    private readonly colorRepository: Repository<Color>,
  ) {}

  async listarCategorias(): Promise<{ id: string; nombre: string }[]> {
    const categorias = await this.categoriaRepository.find({
      where: { activo: true },
      order: { nombre: 'ASC' },
    });
    return categorias.map(({ id, nombre }) => ({ id, nombre }));
  }

  async listarColores(): Promise<{ id: string; nombre: string }[]> {
    const colores = await this.colorRepository.find({
      order: { nombre: 'ASC' },
    });
    return colores.map(({ id, nombre }) => ({ id, nombre }));
  }

  async inventarioPorTalla(
    talla: number,
    filtro: FiltroInventarioTalla = {},
  ): Promise<InventarioTallaResponse> {
    const qb = this.inventarioRepository
      .createQueryBuilder('inv')
      .innerJoinAndSelect('inv.zapato', 'zapato')
      .leftJoinAndSelect('zapato.categoria', 'categoria')
      .leftJoinAndSelect('zapato.precioRangos', 'rango')
      .leftJoinAndSelect('inv.color', 'color')
      .where('inv.talla = :talla', { talla })
      .andWhere('inv.cantidad > 0')
      .orderBy('zapato.nombre', 'ASC')
      .addOrderBy('color.nombre', 'ASC');

    if (filtro.categoriaId) {
      qb.andWhere('zapato.categoriaId = :categoriaId', {
        categoriaId: filtro.categoriaId,
      });
    }
    if (filtro.colorId) {
      qb.andWhere('inv.colorId = :colorId', { colorId: filtro.colorId });
    }

    const filas = await qb.getMany();

    const porZapato = new Map<string, ItemInventarioTalla>();
    for (const fila of filas) {
      let item = porZapato.get(fila.zapatoId);
      if (!item) {
        const z = fila.zapato;
        item = {
          zapatoId: z.id,
          nombre: z.nombre,
          modelo: z.modelo,
          foto: z.foto,
          categoriaId: z.categoriaId ?? null,
          categoria: z.categoria?.nombre ?? null,
          precioPublico: this.precioPublicoParaTalla(
            Number(z.precioPublico),
            z.precioRangos ?? [],
            talla,
          ),
          variantes: [],
        };
        porZapato.set(fila.zapatoId, item);
      }
      item.variantes.push({
        colorId: fila.colorId ?? null,
        color: fila.color?.nombre ?? null,
        cantidad: fila.cantidad,
      });
    }

    return { talla, items: [...porZapato.values()] };
  }

  // Misma regla que ZapatoModel.getPrecioPublicoForTalla en Flutter.
  private precioPublicoParaTalla(
    precioPlano: number,
    rangos: PrecioRango[],
    talla: number,
  ): number {
    for (const r of rangos) {
      if (talla >= r.medidaInicio && talla <= r.medidaFin) {
        return Number(r.precioPublico);
      }
    }
    return precioPlano;
  }
}
