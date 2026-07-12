import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Zapato } from '../entities/zapato.entity';
import { ZapatoColor } from '../entities/zapato-color.entity';
import { PrecioRango } from '../entities/precio-rango.entity';
import { Inventario } from '../entities/inventario.entity';
import { VentaItem } from '../entities/venta-item.entity';
import { ZapatoController } from './zapato.controller';
import { ZapatoService } from './zapato.service';
import { UploadModule } from '../upload/upload.module';
import { MarcaModule } from '../marca/marca.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Zapato,
      ZapatoColor,
      PrecioRango,
      Inventario,
      VentaItem,
    ]),
    UploadModule,
    MarcaModule,
  ],
  controllers: [ZapatoController],
  providers: [ZapatoService],
  exports: [ZapatoService],
})
export class ZapatoModule {}
