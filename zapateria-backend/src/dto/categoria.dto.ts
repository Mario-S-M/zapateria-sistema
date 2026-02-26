import { IsString, IsOptional, IsBoolean, MinLength, MaxLength } from 'class-validator';

export class CreateCategoriaDto {
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  @MaxLength(100, { message: 'El nombre no puede exceder 100 caracteres' })
  nombre: string;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}

export class UpdateCategoriaDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  @MaxLength(100, { message: 'El nombre no puede exceder 100 caracteres' })
  nombre?: string;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}