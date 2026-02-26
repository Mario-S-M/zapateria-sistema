import { IsString, IsOptional, MinLength, IsBoolean } from 'class-validator';

export class CreateColorDto {
  @IsString({ message: 'El nombre debe ser un texto' })
  @MinLength(1, { message: 'El nombre es requerido' })
  nombre: string;

  @IsOptional()
  @IsString({ message: 'El hexadecimal debe ser un texto' })
  hexadecimal?: string;

  @IsOptional()
  @IsBoolean({ message: 'isCombo debe ser booleano' })
  isCombo?: boolean;

  @IsOptional()
  @IsString({ message: 'primaryColor debe ser un texto' })
  primaryColor?: string;

  @IsOptional()
  @IsString({ message: 'secondaryColor debe ser un texto' })
  secondaryColor?: string;
}

export class UpdateColorDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'El nombre es requerido' })
  nombre?: string;

  @IsOptional()
  @IsString()
  hexadecimal?: string;

  @IsOptional()
  @IsBoolean()
  isCombo?: boolean;

  @IsOptional()
  @IsString()
  primaryColor?: string;

  @IsOptional()
  @IsString()
  secondaryColor?: string;
}
