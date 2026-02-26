import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  Query,
} from '@nestjs/common';
import { VentaService } from './venta.service';
import { CreateVentaDto, UpdateVentaDto } from '../dto/venta.dto';

@Controller('ventas')
export class VentaController {
  constructor(private readonly ventaService: VentaService) {}

  @Get()
  findAll() {
    return this.ventaService.findAll();
  }

  @Get('reporte/cierre-caja')
  getCierreCaja(
    @Query('fechaInicio') fechaInicio?: string,
    @Query('fechaFin') fechaFin?: string,
  ) {
    return this.ventaService.getCierreCaja(fechaInicio, fechaFin);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.ventaService.findOne(id);
  }

  @Post()
  create(@Body() createVentaDto: CreateVentaDto) {
    return this.ventaService.create(createVentaDto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateVentaDto: UpdateVentaDto) {
    return this.ventaService.update(id, updateVentaDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.ventaService.remove(id);
  }
}
