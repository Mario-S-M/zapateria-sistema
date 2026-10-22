import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { ApartadoService } from './apartado.service';
import { CreateAbonoDto, CreateApartadoDto } from '../dto/apartado.dto';
import { EstadoApartado } from '../entities/apartado.entity';

@Controller('apartados')
export class ApartadoController {
  constructor(private readonly apartadoService: ApartadoService) {}

  @Get()
  findAll(
    @Query('estado') estado?: EstadoApartado,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.apartadoService.findAll(
      estado,
      page ? parseInt(page, 10) : undefined,
      limit ? parseInt(limit, 10) : undefined,
    );
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.apartadoService.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateApartadoDto) {
    return this.apartadoService.create(dto);
  }

  @Post(':id/abonos')
  addAbono(@Param('id') id: string, @Body() dto: CreateAbonoDto) {
    return this.apartadoService.addAbono(id, dto);
  }

  @Post(':id/entregar')
  entregar(@Param('id') id: string) {
    return this.apartadoService.entregar(id);
  }

  @Post(':id/cancelar')
  cancelar(@Param('id') id: string) {
    return this.apartadoService.cancelar(id);
  }
}
