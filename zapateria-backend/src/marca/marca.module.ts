import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MarcaController } from './marca.controller';
import { MarcaService } from './marca.service';
import { Marca } from '../entities/marca.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Marca])],
  controllers: [MarcaController],
  providers: [MarcaService],
  exports: [MarcaService],
})
export class MarcaModule {}
