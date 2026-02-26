import { IsString, IsOptional, IsEmail, IsBoolean, MinLength } from 'class-validator';

export class CreateInversionistaDto {
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  nombre: string;

  @IsOptional()
  @IsString()
  telefono?: string;

  @IsOptional()
  @IsEmail({}, { message: 'Email inválido' })
  email?: string;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}

export class UpdateInversionistaDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  nombre?: string;

  @IsOptional()
  @IsString()
  telefono?: string;

  @IsOptional()
  @IsEmail({}, { message: 'Email inválido' })
  email?: string;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}
