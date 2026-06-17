import { IsString, IsNumber, IsOptional, IsArray, ValidateNested, Min } from 'class-validator';
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
