import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, Repository } from 'typeorm';
import { Apartado, EstadoApartado } from '../entities/apartado.entity';
import { ApartadoItem } from '../entities/apartado-item.entity';
import { Abono, MetodoAbono } from '../entities/abono.entity';
import { Venta, MetodoPago } from '../entities/venta.entity';
import { VentaItem } from '../entities/venta-item.entity';
import { Inventario } from '../entities/inventario.entity';
import { CreateAbonoDto, CreateApartadoDto } from '../dto/apartado.dto';

const RELATIONS = [
  'inversionista',
  'items',
  'items.zapato',
  'items.zapato.colores',
  'items.zapato.colores.color',
  'abonos',
];

const round2 = (n: number) => Math.round(n * 100) / 100;

@Injectable()
export class ApartadoService {
  constructor(
    @InjectRepository(Apartado)
    private apartadoRepository: Repository<Apartado>,
    private dataSource: DataSource,
  ) {}

  async findAll(estado?: EstadoApartado, page = 1, limit = 12) {
    const [data, total] = await this.apartadoRepository.findAndCount({
      where: estado ? { estado } : {},
      relations: RELATIONS,
      order: { fecha: 'DESC', abonos: { fecha: 'ASC' } },
      skip: (page - 1) * limit,
      take: limit,
    });
    return {
      data,
      total,
      page,
      totalPages: Math.max(1, Math.ceil(total / limit)),
    };
  }

  async findOne(id: string): Promise<Apartado> {
    const apartado = await this.apartadoRepository.findOne({
      where: { id },
      relations: RELATIONS,
      order: { abonos: { fecha: 'ASC' } },
    });
    if (!apartado) throw new NotFoundException('Apartado no encontrado');
    return apartado;
  }

  async create(dto: CreateApartadoDto): Promise<Apartado> {
    const total = round2(
      dto.items.reduce((s, i) => s + i.precioUnitario * i.cantidad, 0),
    );
    if (dto.abonoInicial && round2(dto.abonoInicial.monto) > total) {
      throw new BadRequestException('El abono no puede ser mayor al total');
    }

    const id = await this.dataSource.transaction(async (em) => {
      const apartado = await em.save(
        em.create(Apartado, {
          folio: dto.folio,
          clienteNombre: dto.clienteNombre,
          clienteTelefono: dto.clienteTelefono ?? null,
          tipoPrecio: dto.tipoPrecio,
          inversionistaId: dto.inversionistaId ?? null,
          total,
        }),
      );

      await em.save(
        dto.items.map((i) =>
          em.create(ApartadoItem, {
            apartadoId: apartado.id,
            zapatoId: i.zapatoId,
            cantidad: i.cantidad,
            precioUnitario: i.precioUnitario,
            subtotal: round2(i.precioUnitario * i.cantidad),
            inversionistaId: i.inversionistaId ?? null,
            colorId: i.colorId ?? null,
            talla: i.talla ?? null,
          }),
        ),
      );

      if (dto.abonoInicial) {
        await em.save(
          em.create(Abono, { apartadoId: apartado.id, ...dto.abonoInicial }),
        );
      }

      for (const i of dto.items) {
        await this.ajustarInventario(em, i, -i.cantidad);
      }
      return apartado.id;
    });
    return this.findOne(id);
  }

  async addAbono(id: string, dto: CreateAbonoDto): Promise<Apartado> {
    await this.dataSource.transaction(async (em) => {
      const apartado = await this.bloquear(em, id, ['abonos']);
      this.exigirActivo(apartado);
      const saldo = this.saldo(apartado);
      if (round2(dto.monto) > saldo) {
        throw new BadRequestException(
          `El abono excede el saldo pendiente ($${saldo.toFixed(2)})`,
        );
      }
      await em.save(em.create(Abono, { apartadoId: id, ...dto }));
    });
    return this.findOne(id);
  }

  async entregar(id: string): Promise<Apartado> {
    await this.dataSource.transaction(async (em) => {
      const apartado = await this.bloquear(em, id, ['abonos', 'items']);
      this.exigirActivo(apartado);
      const saldo = this.saldo(apartado);
      if (saldo > 0) {
        throw new BadRequestException(
          `Apartado no liquidado: faltan $${saldo.toFixed(2)}`,
        );
      }

      const montoTarjeta = round2(
        apartado.abonos
          .filter((a) => a.metodoPago === MetodoAbono.TARJETA)
          .reduce((s, a) => s + a.monto, 0),
      );
      const metodoPago =
        montoTarjeta === 0
          ? MetodoPago.EFECTIVO
          : montoTarjeta >= apartado.total
            ? MetodoPago.TARJETA
            : MetodoPago.MIXTO;

      const venta = await em.save(
        em.create(Venta, {
          folio: `V-${Date.now()}`,
          tipoPrecio: apartado.tipoPrecio,
          inversionistaId: apartado.inversionistaId ?? undefined,
          metodoPago,
          montoTarjeta,
          total: apartado.total,
        }),
      );
      // El inventario ya se descontó al crear el apartado.
      await em.save(
        apartado.items.map((i) =>
          em.create(VentaItem, {
            ventaId: venta.id,
            zapatoId: i.zapatoId ?? undefined,
            cantidad: i.cantidad,
            precioUnitario: i.precioUnitario,
            subtotal: i.subtotal,
            inversionistaId: i.inversionistaId ?? undefined,
            colorId: i.colorId ?? undefined,
            talla: i.talla ?? undefined,
          }),
        ),
      );

      apartado.estado = EstadoApartado.ENTREGADO;
      apartado.ventaId = venta.id;
      await em.update(Apartado, id, {
        estado: apartado.estado,
        ventaId: venta.id,
      });
    });
    return this.findOne(id);
  }

  async cancelar(id: string): Promise<Apartado> {
    await this.dataSource.transaction(async (em) => {
      const apartado = await this.bloquear(em, id, ['items']);
      this.exigirActivo(apartado);
      for (const i of apartado.items) {
        await this.ajustarInventario(
          em,
          {
            zapatoId: i.zapatoId ?? undefined,
            colorId: i.colorId ?? undefined,
            talla: i.talla ?? undefined,
          },
          i.cantidad,
        );
      }
      await em.update(Apartado, id, { estado: EstadoApartado.CANCELADO });
    });
    return this.findOne(id);
  }

  /** Bloquea la fila (FOR UPDATE no admite joins) y luego carga relaciones. */
  private async bloquear(
    em: EntityManager,
    id: string,
    relations: ('abonos' | 'items')[],
  ): Promise<Apartado> {
    const apartado = await em.findOne(Apartado, {
      where: { id },
      lock: { mode: 'pessimistic_write' },
    });
    if (!apartado) throw new NotFoundException('Apartado no encontrado');
    if (relations.includes('abonos')) {
      apartado.abonos = await em.find(Abono, { where: { apartadoId: id } });
    }
    if (relations.includes('items')) {
      apartado.items = await em.find(ApartadoItem, {
        where: { apartadoId: id },
      });
    }
    return apartado;
  }

  private saldo(a: Apartado): number {
    const abonado = (a.abonos ?? []).reduce((s, x) => s + x.monto, 0);
    return round2(a.total - abonado);
  }

  private exigirActivo(a: Apartado) {
    if (a.estado !== EstadoApartado.ACTIVO) {
      throw new BadRequestException(
        `El apartado ya está ${a.estado.toLowerCase()}`,
      );
    }
  }

  /** Suma `delta` al stock (negativo descuenta, con piso en 0). */
  private async ajustarInventario(
    em: EntityManager,
    item: { zapatoId?: string; colorId?: string; talla?: number },
    delta: number,
  ) {
    if (!item.zapatoId || !item.colorId || item.talla == null) return;
    const inv = await em.findOne(Inventario, {
      where: {
        zapatoId: item.zapatoId,
        colorId: item.colorId,
        talla: item.talla,
      },
    });
    if (inv) {
      inv.cantidad = Math.max(0, inv.cantidad + delta);
      await em.save(inv);
    }
  }
}
