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
import { InversionistaService } from './inversionista.service';
import {
  CreateInversionistaDto,
  UpdateInversionistaDto,
} from '../dto/inversionista.dto';

@Controller('inversionistas')
export class InversionistaController {
  constructor(private readonly inversionistaService: InversionistaService) {}

  @Get()
  findAll() {
    return this.inversionistaService.findAll();
  }

  @Get('activos')
  findActivos() {
    return this.inversionistaService.findActivos();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.inversionistaService.findOne(id);
  }

  @Post()
  create(@Body() createInversionistaDto: CreateInversionistaDto) {
    return this.inversionistaService.create(createInversionistaDto);
  }

  @Put(':id')
  update(
    @Param('id') id: string,
    @Body() updateInversionistaDto: UpdateInversionistaDto,
  ) {
    return this.inversionistaService.update(id, updateInversionistaDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id') id: string) {
    return this.inversionistaService.remove(id);
  }
}
