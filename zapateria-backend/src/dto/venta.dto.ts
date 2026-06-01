import {
  IsString,
  IsNumber,
  IsArray,
  IsOptional,
  IsEnum,
  MinLength,
  Min,
  ValidateNested,
  ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MetodoPago, TipoPrecio } from '../entities/venta.entity';

export class VentaItemDto {
  @IsString()
  @MinLength(1, { message: 'El zapato es requerido' })
  zapatoId: string;

  @IsNumber()
  @Min(1, { message: 'La cantidad debe ser mayor a 0' })
  cantidad: number;

  @IsNumber()
  @Min(0, { message: 'El precio unitario debe ser mayor o igual a 0' })
  precioUnitario: number;

  @IsOptional()
  @IsString()
  inversionistaId?: string;
}

export class CreateVentaDto {
  @IsString()
  @MinLength(1, { message: 'El folio es requerido' })
  folio: string;

  @IsEnum(TipoPrecio)
  tipoPrecio: TipoPrecio;

  @IsOptional()
  @IsString()
  inversionistaId?: string;

  @IsOptional()
  @IsEnum(MetodoPago)
  metodoPago?: MetodoPago;

  @IsOptional()
  @IsNumber()
  @Min(0)
  montoTarjeta?: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VentaItemDto)
  @ArrayMinSize(1, { message: 'Debe haber al menos un item en la venta' })
  items: VentaItemDto[];
}

export class UpdateVentaDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El folio es requerido' })
  folio?: string;

  @IsOptional()
  @IsEnum(TipoPrecio)
  tipoPrecio?: TipoPrecio;

  @IsOptional()
  @IsString()
  inversionistaId?: string;

  @IsOptional()
  @IsEnum(MetodoPago)
  metodoPago?: MetodoPago;

  @IsOptional()
  @IsNumber()
  @Min(0)
  montoTarjeta?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VentaItemDto)
  @ArrayMinSize(1, { message: 'Debe haber al menos un item en la venta' })
  items?: VentaItemDto[];
}
