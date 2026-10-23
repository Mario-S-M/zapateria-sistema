import {
  BadGatewayException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PlataformaAgente } from '../dto/agente.dto';

const ELEVENLABS_API = 'https://api.elevenlabs.io/v1/convai/conversation';
const TIMEOUT_MS = 10000;

export interface SesionAgenteResponse {
  plataforma: PlataformaAgente;
  conversationToken: string;
  signedUrl: string;
}

@Injectable()
export class AgenteSesionService {
  private readonly logger = new Logger(AgenteSesionService.name);

  async crearSesion(
    plataforma: PlataformaAgente,
  ): Promise<SesionAgenteResponse> {
    const apiKey = process.env.ELEVENLABS_API_KEY;
    const agentId = process.env.ELEVENLABS_AGENT_ID;
    if (!apiKey || !agentId) {
      throw new ServiceUnavailableException(
        'El asesor no está configurado: faltan ELEVENLABS_API_KEY o ELEVENLABS_AGENT_ID en el backend',
      );
    }

    // El token (WebRTC) abre la sesión de voz; la signed URL (WebSocket) la de solo texto,
    // que no necesita micrófono. Ambas plataformas reciben las dos.
    const [conversationToken, signedUrl] = await Promise.all([
      this.pedirToken(apiKey, agentId),
      this.pedirSignedUrl(apiKey, agentId),
    ]);
    return { plataforma, conversationToken, signedUrl };
  }

  private async pedirToken(apiKey: string, agentId: string): Promise<string> {
    const data = await this.llamar<{ token?: string }>(
      `${ELEVENLABS_API}/token`,
      apiKey,
      agentId,
    );
    if (!data.token) throw this.respuestaInvalida('token');
    return data.token;
  }

  private async pedirSignedUrl(
    apiKey: string,
    agentId: string,
  ): Promise<string> {
    const data = await this.llamar<{ signed_url?: string }>(
      `${ELEVENLABS_API}/get-signed-url`,
      apiKey,
      agentId,
    );
    if (!data.signed_url) throw this.respuestaInvalida('signed_url');
    return data.signed_url;
  }

  private async llamar<T>(
    url: string,
    apiKey: string,
    agentId: string,
  ): Promise<T> {
    let res: Response;
    try {
      res = await fetch(`${url}?agent_id=${encodeURIComponent(agentId)}`, {
        headers: { 'xi-api-key': apiKey },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
    } catch (err) {
      this.logger.error(
        `No se pudo contactar a ElevenLabs: ${(err as Error).message}`,
      );
      throw new BadGatewayException(
        'No se pudo contactar al servicio del asesor',
      );
    }
    if (!res.ok) {
      // No se reenvía el cuerpo: puede incluir detalles de la cuenta.
      this.logger.error(`ElevenLabs respondió ${res.status} en ${url}`);
      throw new BadGatewayException(
        `El servicio del asesor respondió con error (${res.status})`,
      );
    }
    return (await res.json()) as T;
  }

  private respuestaInvalida(campo: string): BadGatewayException {
    this.logger.error(`Respuesta de ElevenLabs sin ${campo}`);
    return new BadGatewayException(
      'Respuesta inválida del servicio del asesor',
    );
  }
}
