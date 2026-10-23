import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { timingSafeEqual } from 'crypto';
import { Request } from 'express';

@Injectable()
export class McpSecretGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const esperado = process.env.MCP_SHARED_SECRET;
    if (!esperado) {
      throw new ServiceUnavailableException(
        'MCP_SHARED_SECRET no está configurado',
      );
    }
    const req = context.switchToHttp().getRequest<Request>();
    const recibido = req.header('x-mcp-secret') ?? '';

    const a = Buffer.from(recibido);
    const b = Buffer.from(esperado);
    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      throw new UnauthorizedException();
    }
    return true;
  }
}
