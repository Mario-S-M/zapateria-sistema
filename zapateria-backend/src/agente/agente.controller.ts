import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
} from '@nestjs/common';
import { AgenteService } from './agente.service';
import { AgenteSesionService } from './agente-sesion.service';
import { CreateSesionAgenteDto } from '../dto/agente.dto';

@Controller('agente')
export class AgenteController {
  constructor(
    private readonly agenteService: AgenteService,
    private readonly sesionService: AgenteSesionService,
  ) {}

  @Post('sesion')
  crearSesion(@Body() dto: CreateSesionAgenteDto) {
    return this.sesionService.crearSesion(dto.plataforma);
  }

  @Get('inventario')
  inventarioPorTalla(
    @Query('talla') talla?: string,
    @Query('categoriaId') categoriaId?: string,
  ) {
    const tallaNum = Number(talla);
    if (!talla || !Number.isFinite(tallaNum) || tallaNum <= 0) {
      throw new BadRequestException(
        'talla es requerida y debe ser un número positivo',
      );
    }
    return this.agenteService.inventarioPorTalla(tallaNum, { categoriaId });
  }
}
