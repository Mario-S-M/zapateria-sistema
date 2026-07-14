import {
  IsString,
  IsNumber,
  IsOptional,
  IsArray,
  IsInt,
  ValidateNested,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';

export class InventarioItemDto {
  @IsString()
  zapatoId: string;

  @IsOptional()
  @IsString()
  colorId?: string;

  @IsNumber()
  @Min(0)
  talla: number;

  @IsNumber()
  @Min(0)
  cantidad: number;
}

export class BulkUpsertInventarioDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InventarioItemDto)
  items: InventarioItemDto[];
}

export class IncrementInventarioDto {
  @IsString()
  zapatoId: string;

  @IsOptional()
  @IsString()
  colorId?: string;

  @IsNumber()
  @Min(0)
  talla: number;

  @IsInt()
  @Min(-1000)
  @Max(1000)
  delta: number;
}
