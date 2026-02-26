import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Zapato } from '../entities/zapato.entity';
import { ZapatoColor } from '../entities/zapato-color.entity';
import { ZapatoController } from './zapato.controller';
import { ZapatoService } from './zapato.service';
import { UploadModule } from '../upload/upload.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Zapato, ZapatoColor]),
    UploadModule,
  ],
  controllers: [ZapatoController],
  providers: [ZapatoService],
  exports: [ZapatoService],
})
export class ZapatoModule {}
