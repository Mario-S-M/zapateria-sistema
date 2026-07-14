import {
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  IsIn,
  IsInt,
  Min,
  MinLength,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import type { BarcodeSegmentoTipo } from '../entities/marca.entity';

export class BarcodeSegmentoDto {
  @IsIn(['fijo', 'modelo', 'lote', 'talla'])
  tipo: BarcodeSegmentoTipo;

  @IsInt()
  @Min(0)
  inicio: number;

  @IsInt()
  @Min(1)
  longitud: number;

  @IsOptional()
  @IsBoolean()
  decimalImplicito?: boolean;
}

export class CreateMarcaDto {
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  @MaxLength(100, { message: 'El nombre no puede exceder 100 caracteres' })
  nombre: string;

  @IsOptional()
  @IsString()
  codigoEjemplo?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BarcodeSegmentoDto)
  patronSegmentos?: BarcodeSegmentoDto[];

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}

export class UpdateMarcaDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  @MaxLength(100, { message: 'El nombre no puede exceder 100 caracteres' })
  nombre?: string;

  @IsOptional()
  @IsString()
  codigoEjemplo?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BarcodeSegmentoDto)
  patronSegmentos?: BarcodeSegmentoDto[];

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}
