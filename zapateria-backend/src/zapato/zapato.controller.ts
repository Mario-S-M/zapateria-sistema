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
} from '@nestjs/common';
import { ZapatoService } from './zapato.service';
import { CreateZapatoDto, UpdateZapatoDto } from '../dto/zapato.dto';

@Controller('zapatos')
export class ZapatoController {
  constructor(private readonly zapatoService: ZapatoService) {}

  @Get()
  findAll() {
    return this.zapatoService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.zapatoService.findOne(id);
  }

  @Get('codigo/:codigoBarras')
  findByCodigoBarras(@Param('codigoBarras') codigoBarras: string) {
    return this.zapatoService.findByCodigoBarras(codigoBarras);
  }

  @Post()
  create(@Body() createZapatoDto: CreateZapatoDto) {
    return this.zapatoService.create(createZapatoDto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateZapatoDto: UpdateZapatoDto) {
    return this.zapatoService.update(id, updateZapatoDto);
  }

  @Post(':id/merge/:duplicateId')
  merge(
    @Param('id') id: string,
    @Param('duplicateId') duplicateId: string,
  ) {
    return this.zapatoService.merge(id, duplicateId);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.zapatoService.remove(id);
  }
}
