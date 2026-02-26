import {
  IsString,
  IsNumber,
  IsArray,
  IsOptional,
  MinLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateZapatoDto {
  @IsString()
  @MinLength(1, { message: 'El código de barras es requerido' })
  codigoBarras: string;

  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  nombre: string;

  @IsString()
  @MinLength(1, { message: 'El modelo es requerido' })
  modelo: string;

  @IsString()
  @MinLength(1, { message: 'La foto es requerida' })
  foto: string;

  @IsNumber()
  @Min(0, { message: 'El precio de compra debe ser mayor o igual a 0' })
  precioCompra: number;

  @IsNumber()
  @Min(0, { message: 'El precio público debe ser mayor o igual a 0' })
  precioPublico: number;

  @IsNumber()
  @Min(0, { message: 'La medida inicial es requerida' })
  medidaInicio: number;

  @IsNumber()
  @Min(0, { message: 'La medida final es requerida' })
  medidaFin: number;

  @IsArray()
  @IsString({ each: true })
  @MinLength(1, { each: true })
  colorIds: string[];

  @IsOptional()
  @IsString()
  categoriaId?: string;

  @IsString()
  @MinLength(1, { message: 'El inversionista es requerido' })
  inversionistaId: string;
}

export class UpdateZapatoDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El código de barras es requerido' })
  codigoBarras?: string;

  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  nombre?: string;

  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El modelo es requerido' })
  modelo?: string;

  @IsOptional()
  @IsString()
  foto?: string;

  @IsOptional()
  @IsNumber()
  @Min(0, { message: 'El precio de compra debe ser mayor o igual a 0' })
  precioCompra?: number;

  @IsOptional()
  @IsNumber()
  @Min(0, { message: 'El precio público debe ser mayor o igual a 0' })
  precioPublico?: number;

  @IsOptional()
  @IsNumber()
  @Min(0, { message: 'La medida inicial es requerida' })
  medidaInicio?: number;

  @IsOptional()
  @IsNumber()
  @Min(0, { message: 'La medida final es requerida' })
  medidaFin?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @MinLength(1, { each: true })
  colorIds?: string[];

  @IsOptional()
  @IsString()
  categoriaId?: string;

  @IsOptional()
  @IsString()
  inversionistaId?: string;
}
