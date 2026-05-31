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
      console.log('🔍 getCierreCaja - Parámetros:', { fechaInicio, fechaFin });

      // Primero: obtener todos los venta items con sus relaciones
      const allItems = await this.ventaItemRepository.find({
        relations: ['venta', 'inversionista'],
        order: { venta: { fecha: 'DESC' } }
      });

      console.log(`📊 Total de items encontrados en BD: ${allItems.length}`);
      if (allItems.length > 0) {
        console.log(`📅 Primera venta: ${allItems[0].venta?.fecha}`);
      }

      // Construct query to get venta items grouped by date and investor
      let query = this.ventaItemRepository
        .createQueryBuilder('vi')
        .innerJoin('vi.venta', 'v')
        .leftJoin('v.inversionista', 'i')
        .select('TO_CHAR(v.fecha, \'YYYY-MM-DD\')', 'fecha')
        .addSelect('COALESCE(i.id, v.inversionistaId)', 'inversionistaId')
        .addSelect('COALESCE(i.nombre, \'Sin Inversionista\')', 'inversionistaNombre')
        .addSelect('COUNT(vi.id)', 'totalItems')
        .addSelect('SUM(vi.subtotal)', 'totalVendido');

      if (fechaInicio) {
        console.log(`📅 Filtrando desde: ${fechaInicio}`);
        query = query.andWhere(
          `DATE(v.fecha) >= :fechaInicio`,
          { fechaInicio }
        );
      }

      if (fechaFin) {
        console.log(`📅 Filtrando hasta: ${fechaFin}`);
        query = query.andWhere(
          `DATE(v.fecha) <= :fechaFin`,
          { fechaFin }
        );
      }

      const resultados = await query
        .groupBy('TO_CHAR(v.fecha, \'YYYY-MM-DD\')')
        .addGroupBy('COALESCE(i.id, v.inversionistaId)')
        .addGroupBy('COALESCE(i.nombre, \'Sin Inversionista\')')
        .orderBy('TO_CHAR(v.fecha, \'YYYY-MM-DD\')', 'DESC')
        .addOrderBy('COALESCE(i.nombre, \'Sin Inversionista\')', 'ASC')
        .getRawMany();

      console.log(`✅ Resultados de groupBy: ${resultados.length}`, resultados);

      // Agrupar por fecha
      const reportePorFecha = resultados.reduce((acc, item) => {
        const fecha = item.fecha;
        if (!acc[fecha]) {
          acc[fecha] = {
            fecha,
            inversionistas: [],
            totalDia: 0,
          };
        }

        const totalInversionista = parseFloat(item.totalVendido) || 0;
        
        acc[fecha].inversionistas.push({
          inversionistaId: item.inversionistaId,
          nombre: item.inversionistaNombre || 'Sin Inversionista',
          totalItems: parseInt(item.totalItems) || 0,
          total: totalInversionista,
        });

        acc[fecha].totalDia += totalInversionista;

        return acc;
      }, {});

      const resultado = Object.values(reportePorFecha);
      console.log(`📊 Resultado final con ${resultado.length} días:`, resultado);
      return resultado;
    } catch (error) {
      console.error('❌ Error in getCierreCaja:', error);
      // Return empty array on error to prevent crashes
      return [];
    }
  }
}
