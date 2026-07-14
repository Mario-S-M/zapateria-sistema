import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { InventarioService } from './inventario.service';
import {
  BulkUpsertInventarioDto,
  IncrementInventarioDto,
} from '../dto/inventario.dto';

@Controller('inventario')
export class InventarioController {
  constructor(private readonly inventarioService: InventarioService) {}

  @Get()
  findAll() {
    return this.inventarioService.findAll();
  }

  @Get('zapato/:zapatoId')
  getByZapato(@Param('zapatoId') zapatoId: string) {
    return this.inventarioService.getByZapato(zapatoId);
  }

  @Post('bulk')
  bulkUpsert(@Body() dto: BulkUpsertInventarioDto) {
    return this.inventarioService.bulkUpsert(dto.items);
  }

  @Post('increment')
  increment(@Body() dto: IncrementInventarioDto) {
    return this.inventarioService.increment(
      dto.zapatoId,
      dto.colorId ?? null,
      dto.talla,
      dto.delta,
    );
  }
}
