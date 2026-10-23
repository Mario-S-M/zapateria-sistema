import { IsIn } from 'class-validator';

export const PLATAFORMAS_AGENTE = ['web', 'movil'] as const;
export type PlataformaAgente = (typeof PLATAFORMAS_AGENTE)[number];

export class CreateSesionAgenteDto {
  @IsIn(PLATAFORMAS_AGENTE, {
    message: 'plataforma debe ser "web" o "movil"',
  })
  plataforma: PlataformaAgente;
}
