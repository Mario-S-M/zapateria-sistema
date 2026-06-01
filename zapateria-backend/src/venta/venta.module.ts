import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Venta } from '../entities/venta.entity';
import { VentaItem } from '../entities/venta-item.entity';
import { Inversionista } from '../entities/inversionista.entity';
import { VentaController } from './venta.controller';
import { VentaService } from './venta.service';

@Module({
  imports: [TypeOrmModule.forFeature([Venta, VentaItem, Inversionista])],
  controllers: [VentaController],
  providers: [VentaService],
  exports: [VentaService],
})
export class VentaModule {}
