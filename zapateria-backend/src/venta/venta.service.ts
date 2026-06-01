import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Venta } from '../entities/venta.entity';
import { VentaItem } from '../entities/venta-item.entity';
import { CreateVentaDto, UpdateVentaDto } from '../dto/venta.dto';

@Injectable()
export class VentaService {
  constructor(
    @InjectRepository(Venta)
    private ventaRepository: Repository<Venta>,
    @InjectRepository(VentaItem)
    private ventaItemRepository: Repository<VentaItem>,
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

    // Calculate new total if items are being updated
    let total = existingVenta.total;
    if (updateVentaDto.items) {
      total = updateVentaDto.items.reduce(
        (sum, item) => sum + item.precioUnitario * item.cantidad,
        0,
      );
    }

    // Update venta data
    await this.ventaRepository.update(id, {
      folio: updateVentaDto.folio ?? existingVenta.folio,
      tipoPrecio: updateVentaDto.tipoPrecio ?? existingVenta.tipoPrecio,
      inversionistaId: updateVentaDto.inversionistaId ?? existingVenta.inversionistaId,
      total,
    });

    // If items are being updated, remove existing items and create new ones
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
        .addSelect('TO_CHAR(v.fecha AT TIME ZONE \'UTC\', \'YYYY-MM-DD"T"HH24:MI:SS"Z"\')', 'ventaFecha');

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

      // Group by fecha → investor in TypeScript to include individual articles
      const byFecha: Record<string, any> = {};

      for (const row of rows) {
        const fecha = row.fecha;
        if (!byFecha[fecha]) {
          byFecha[fecha] = { fecha, inversionistas: {}, totalDia: 0 };
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
      }

      return Object.values(byFecha).map((d: any) => ({
        fecha: d.fecha,
        totalDia: d.totalDia,
        inversionistas: Object.values(d.inversionistas),
      }));
    } catch (error) {
      console.error('❌ Error in getCierreCaja:', error);
      return [];
    }
  }
}
