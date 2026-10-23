import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Inventario } from '../entities/inventario.entity';
import { Categoria } from '../entities/categoria.entity';
import { Color } from '../entities/color.entity';
import { AgenteController } from './agente.controller';
import { AgenteService } from './agente.service';
import { AgenteSesionService } from './agente-sesion.service';
import { McpController } from './mcp.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Inventario, Categoria, Color])],
  controllers: [AgenteController, McpController],
  providers: [AgenteService, AgenteSesionService],
  exports: [AgenteService],
})
export class AgenteModule {}
