import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Venta } from '../entities/venta.entity';
import { VentaItem } from '../entities/venta-item.entity';
import { Inversionista } from '../entities/inversionista.entity';
import { CreateVentaDto, UpdateVentaDto } from '../dto/venta.dto';

@Injectable()
export class VentaService {
  constructor(
    @InjectRepository(Venta)
    private ventaRepository: Repository<Venta>,
    @InjectRepository(VentaItem)
    private ventaItemRepository: Repository<VentaItem>,
    @InjectRepository(Inversionista)
    private inversionistaRepository: Repository<Inversionista>,
  ) {}

  async findAll(): Promise<Venta[]> {
    return this.ventaRepository.find({
      relations: [
        'inversionista',
        'items',
        'items.zapato',
        'items.zapato.colores',
        'items.zapato.colores.color',
      ],
      order: { fecha: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Venta | null> {
    return this.ventaRepository.findOne({
      where: { id },
      relations: [
        'inversionista',
        'items',
        'items.zapato',
        'items.zapato.colores',
        'items.zapato.colores.color',
      ],
    });
  }

  async create(createVentaDto: CreateVentaDto): Promise<Venta | null> {
    const total = createVentaDto.items.reduce(
      (sum, item) => sum + item.precioUnitario * item.cantidad,
      0,
    );

    const venta = this.ventaRepository.create({
      folio: createVentaDto.folio,
      tipoPrecio: createVentaDto.tipoPrecio,
      inversionistaId: createVentaDto.inversionistaId,
      metodoPago: createVentaDto.metodoPago,
      montoTarjeta: createVentaDto.montoTarjeta ?? 0,
      total,
    });

    const savedVenta = await this.ventaRepository.save(venta);

    const ventaItems = createVentaDto.items.map((item) =>
      this.ventaItemRepository.create({
        ventaId: savedVenta.id,
        zapatoId: item.zapatoId,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        subtotal: item.precioUnitario * item.cantidad,
        inversionistaId: item.inversionistaId,
      }),
    );

    await this.ventaItemRepository.save(ventaItems);

    return this.findOne(savedVenta.id);
  }

  async update(id: string, updateVentaDto: UpdateVentaDto): Promise<Venta | null> {
    const existingVenta = await this.findOne(id);
    if (!existingVenta) {
      throw new NotFoundException(`Venta con ID ${id} no encontrada`);
    }

    let total = existingVenta.total;
    if (updateVentaDto.items) {
      total = updateVentaDto.items.reduce(
        (sum, item) => sum + item.precioUnitario * item.cantidad,
        0,
      );
    }

    await this.ventaRepository.update(id, {
      folio: updateVentaDto.folio ?? existingVenta.folio,
      tipoPrecio: updateVentaDto.tipoPrecio ?? existingVenta.tipoPrecio,
      inversionistaId: updateVentaDto.inversionistaId ?? existingVenta.inversionistaId,
      metodoPago: updateVentaDto.metodoPago ?? existingVenta.metodoPago,
      montoTarjeta: updateVentaDto.montoTarjeta ?? existingVenta.montoTarjeta,
      total,
    });

    if (updateVentaDto.items) {
      await this.ventaItemRepository.delete({ ventaId: id });

      const ventaItems = updateVentaDto.items.map((item) =>
        this.ventaItemRepository.create({
          ventaId: id,
          zapatoId: item.zapatoId,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          subtotal: item.precioUnitario * item.cantidad,
          inversionistaId: item.inversionistaId,
        }),
      );

      await this.ventaItemRepository.save(ventaItems);
    }

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const existingVenta = await this.findOne(id);
    if (!existingVenta) {
      throw new NotFoundException(`Venta con ID ${id} no encontrada`);
    }

    await this.ventaRepository.delete(id);
  }

  async getCierreCaja(fechaInicio?: string, fechaFin?: string) {
    try {
      let query = this.ventaItemRepository
        .createQueryBuilder('vi')
        .innerJoin('vi.venta', 'v')
        .leftJoin('vi.zapato', 'z')
        .leftJoin('z.inversionista', 'i')
        .select('TO_CHAR(v.fecha, \'YYYY-MM-DD\')', 'fecha')
        .addSelect('COALESCE(i.id, z."inversionistaId")', 'inversionistaId')
        .addSelect('COALESCE(i.nombre, \'Sin Inversionista\')', 'inversionistaNombre')
        .addSelect('vi.id', 'itemId')
        .addSelect('vi.cantidad', 'cantidad')
        .addSelect('vi.precioUnitario', 'precioUnitario')
        .addSelect('vi.subtotal', 'subtotal')
        .addSelect('z.id', 'zapatoId')
        .addSelect('z.nombre', 'zapatoNombre')
        .addSelect('z.modelo', 'zapatoModelo')
        .addSelect('z.foto', 'zapatoFoto')
        .addSelect('TO_CHAR(v.fecha AT TIME ZONE \'UTC\', \'YYYY-MM-DD"T"HH24:MI:SS"Z"\')', 'ventaFecha')
        .addSelect('v.id', 'ventaId')
        .addSelect('v.montoTarjeta', 'montoTarjeta');

      if (fechaInicio) {
        query = query.andWhere(`DATE(v.fecha) >= :fechaInicio`, { fechaInicio });
      }
      if (fechaFin) {
        query = query.andWhere(`DATE(v.fecha) <= :fechaFin`, { fechaFin });
      }

      const rows = await query
        .orderBy('TO_CHAR(v.fecha, \'YYYY-MM-DD\')', 'DESC')
        .addOrderBy('COALESCE(i.nombre, \'Sin Inversionista\')', 'ASC')
        .getRawMany();

      const terminal = await this.inversionistaRepository.findOne({
        where: { tieneTerminal: true },
      });
      const terminalId = terminal?.id ?? null;
      const terminalNombre = terminal?.nombre ?? null;

      const byFecha: Record<string, any> = {};

      for (const row of rows) {
        const fecha = row.fecha;
        if (!byFecha[fecha]) {
          byFecha[fecha] = { fecha, inversionistas: {}, ventasCard: {}, totalDia: 0 };
        }

        const invKey = row.inversionistaId ?? `_${row.inversionistaNombre}`;
        if (!byFecha[fecha].inversionistas[invKey]) {
          byFecha[fecha].inversionistas[invKey] = {
            inversionistaId: row.inversionistaId ?? null,
            nombre: row.inversionistaNombre || 'Sin Inversionista',
            totalItems: 0,
            total: 0,
            articulos: [],
          };
        }

        const inv = byFecha[fecha].inversionistas[invKey];
        const subtotal = parseFloat(row.subtotal) || 0;
        const cantidad = parseInt(row.cantidad) || 1;

        inv.totalItems += cantidad;
        inv.total += subtotal;
        inv.articulos.push({
          zapatoId: row.zapatoId ?? null,
          nombre: row.zapatoNombre || 'Artículo',
          modelo: row.zapatoModelo ?? null,
          foto: row.zapatoFoto ?? null,
          cantidad,
          precioUnitario: parseFloat(row.precioUnitario) || 0,
          subtotal,
          hora: row.ventaFecha ?? null,
        });

        byFecha[fecha].totalDia += subtotal;

        // Track per-venta card data
        if (!byFecha[fecha].ventasCard[row.ventaId]) {
          byFecha[fecha].ventasCard[row.ventaId] = {
            montoTarjeta: parseFloat(row.montoTarjeta) || 0,
            items: [],
          };
        }
        byFecha[fecha].ventasCard[row.ventaId].items.push({
          invId: row.inversionistaId ?? null,
          invNombre: row.inversionistaNombre || 'Sin Inversionista',
          subtotal,
        });
      }

      // Compute card debts per day
      for (const fechaData of Object.values(byFecha) as any[]) {
        const deudasMap: Record<string, { nombre: string; monto: number }> = {};

        for (const ventaCard of Object.values(fechaData.ventasCard) as any[]) {
          if (ventaCard.montoTarjeta <= 0) continue;

          const eduItems = terminalId
            ? ventaCard.items.filter((i: any) => i.invId === terminalId)
            : [];
          const otherItems = terminalId
            ? ventaCard.items.filter((i: any) => i.invId !== terminalId)
            : [];

          let cardLeft = ventaCard.montoTarjeta;

          for (const item of eduItems) {
            const absorbed = Math.min(cardLeft, item.subtotal);
            cardLeft -= absorbed;
            if (cardLeft <= 0) break;
          }

          for (const item of otherItems) {
            if (cardLeft <= 0) break;
            const covered = Math.min(cardLeft, item.subtotal);
            cardLeft -= covered;

            if (covered > 0 && item.invId) {
              if (!deudasMap[item.invId]) {
                deudasMap[item.invId] = { nombre: item.invNombre, monto: 0 };
              }
              deudasMap[item.invId].monto += covered;
            }
          }
        }

        const deudasArr = Object.entries(deudasMap).map(([id, d]) => ({
          acreedorId: id,
          acreedorNombre: d.nombre,
          monto: d.monto,
        }));

        const totalDeuda = deudasArr.reduce((s, d) => s + d.monto, 0);
        if (terminalId && fechaData.inversionistas[terminalId] && totalDeuda > 0) {
          fechaData.inversionistas[terminalId].total -= totalDeuda;
        }

        fechaData.deudasTarjeta = deudasArr;
        fechaData.terminalNombre = terminalNombre;
      }

      return Object.values(byFecha).map((d: any) => ({
        fecha: d.fecha,
        totalDia: d.totalDia,
        inversionistas: Object.values(d.inversionistas),
        deudasTarjeta: d.deudasTarjeta ?? [],
        terminalNombre: d.terminalNombre ?? null,
      }));
    } catch (error) {
      console.error('❌ Error in getCierreCaja:', error);
      return [];
    }
  }
}
