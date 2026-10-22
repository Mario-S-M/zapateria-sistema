import {
  IsString,
  IsNumber,
  IsArray,
  IsOptional,
  IsEnum,
  IsNotEmpty,
  Matches,
  Min,
  ValidateNested,
  ArrayMinSize,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { TipoPrecio } from '../entities/venta.entity';
import { MetodoAbono } from '../entities/abono.entity';
import { VentaItemDto } from './venta.dto';

export class CreateAbonoDto {
  @IsNumber()
  @Min(0.01, { message: 'El monto debe ser mayor a 0' })
  monto: number;

  @IsEnum(MetodoAbono)
  metodoPago: MetodoAbono;
}

export class CreateApartadoDto {
  @IsString()
  @IsNotEmpty({ message: 'El folio es requerido' })
  folio: string;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @IsNotEmpty({ message: 'El nombre del cliente es requerido' })
  clienteNombre: string;

  // Se guarda solo con dígitos: cualquier guion o espacio se descarta.
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => {
    if (typeof value !== 'string') return value;
    const digitos = value.replace(/\D/g, '');
    return digitos === '' ? undefined : digitos;
  })
  @IsString()
  @Matches(/^\d{10}$/, { message: 'El teléfono debe tener 10 dígitos' })
  clienteTelefono?: string;

  @IsEnum(TipoPrecio)
  tipoPrecio: TipoPrecio;

  @IsOptional()
  @IsString()
  inversionistaId?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VentaItemDto)
  @ArrayMinSize(1, { message: 'Debe haber al menos un item en el apartado' })
  items: VentaItemDto[];

  @IsOptional()
  @ValidateNested()
  @Type(() => CreateAbonoDto)
  abonoInicial?: CreateAbonoDto;
}
