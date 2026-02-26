import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ColorModule } from './color/color.module';
import { ZapatoModule } from './zapato/zapato.module';
import { InversionistaModule } from './inversionista/inversionista.module';
import { VentaModule } from './venta/venta.module';
import { UploadModule } from './upload/upload.module';
import { CategoriaModule } from './categoria/categoria.module';
import { Color } from './entities/color.entity';
import { Zapato } from './entities/zapato.entity';
import { ZapatoColor } from './entities/zapato-color.entity';
import { Inversionista } from './entities/inversionista.entity';
import { Venta } from './entities/venta.entity';
import { VentaItem } from './entities/venta-item.entity';
import { Categoria } from './entities/categoria.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      username: process.env.DB_USERNAME || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_DATABASE || 'zapateria',
      entities: [Color, Zapato, ZapatoColor, Inversionista, Venta, VentaItem, Categoria],
      synchronize: true,
      retryAttempts: 3,
      retryDelay: 3000,
      connectTimeoutMS: 60000,
      extra: {
        max: 10,
        min: 1,
        idle: 10000,
      },
    }),
    ColorModule,
    ZapatoModule,
    InversionistaModule,
    VentaModule,
    UploadModule,
    CategoriaModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
