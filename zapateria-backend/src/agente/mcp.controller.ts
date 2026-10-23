import {
  Controller,
  Delete,
  Get,
  HttpCode,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { z } from 'zod';
import { AgenteService } from './agente.service';
import { McpSecretGuard } from './mcp-secret.guard';

const SOLO_LECTURA = { readOnlyHint: true, openWorldHint: false };

const comoTexto = (data: unknown) => ({
  content: [{ type: 'text' as const, text: JSON.stringify(data) }],
});

// Servidor MCP sin estado: cada POST crea su propio server + transport.
// Todas las tools son de solo lectura (ver SPEC 01).
@Controller('mcp')
@UseGuards(McpSecretGuard)
export class McpController {
  constructor(private readonly agenteService: AgenteService) {}

  @Post()
  async handle(@Req() req: Request, @Res() res: Response) {
    const server = this.crearServidor();
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true,
    });
    res.on('close', () => {
      void transport.close();
      void server.close();
    });
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  }

  @Get()
  @Delete()
  @HttpCode(405)
  noPermitido(@Res() res: Response) {
    res.setHeader('Allow', 'POST').send({
      jsonrpc: '2.0',
      error: { code: -32000, message: 'Método no permitido' },
      id: null,
    });
  }

  private crearServidor(): McpServer {
    const server = new McpServer({
      name: 'zapateria-inventario',
      version: '1.0.0',
    });

    server.registerTool(
      'buscar_inventario_por_talla',
      {
        description:
          'Devuelve el calzado con existencia (cantidad > 0) en una talla exacta, agrupado por zapato y color. ' +
          'Úsalo para saber qué hay realmente antes de recomendar. Filtros opcionales por color y categoría.',
        inputSchema: {
          talla: z.number().positive().describe('Talla exacta, ej. 23 o 23.5'),
          colorId: z
            .string()
            .optional()
            .describe('Id de color (de listar_colores)'),
          categoriaId: z
            .string()
            .optional()
            .describe('Id de categoría (de listar_categorias)'),
        },
        annotations: SOLO_LECTURA,
      },
      async ({ talla, colorId, categoriaId }) =>
        comoTexto(
          await this.agenteService.inventarioPorTalla(talla, {
            colorId,
            categoriaId,
          }),
        ),
    );

    server.registerTool(
      'listar_categorias',
      {
        description: 'Lista las categorías de calzado activas con su id.',
        annotations: SOLO_LECTURA,
      },
      async () => comoTexto(await this.agenteService.listarCategorias()),
    );

    server.registerTool(
      'listar_colores',
      {
        description: 'Lista los colores (sólidos y combinados) con su id.',
        annotations: SOLO_LECTURA,
      },
      async () => comoTexto(await this.agenteService.listarColores()),
    );

    return server;
  }
}
