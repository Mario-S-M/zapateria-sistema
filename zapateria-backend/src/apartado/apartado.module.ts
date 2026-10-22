import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Apartado } from '../entities/apartado.entity';
import { ApartadoItem } from '../entities/apartado-item.entity';
import { Abono } from '../entities/abono.entity';
import { ApartadoController } from './apartado.controller';
import { ApartadoService } from './apartado.service';

@Module({
  imports: [TypeOrmModule.forFeature([Apartado, ApartadoItem, Abono])],
  controllers: [ApartadoController],
  providers: [ApartadoService],
})
export class ApartadoModule {}
