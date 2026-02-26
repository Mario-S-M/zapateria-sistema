import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Inversionista } from '../entities/inversionista.entity';
import { InversionistaController } from './inversionista.controller';
import { InversionistaService } from './inversionista.service';

@Module({
  imports: [TypeOrmModule.forFeature([Inversionista])],
  controllers: [InversionistaController],
  providers: [InversionistaService],
  exports: [InversionistaService],
})
export class InversionistaModule {}
