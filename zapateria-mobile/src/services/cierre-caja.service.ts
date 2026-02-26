import api from '../lib/api';

export interface CierreCajaInversionista {
  inversionistaId: string;
  nombre: string;
  totalItems: number;
  total: number;
}

export interface CierreCajaDia {
  fecha: string;
  inversionistas: CierreCajaInversionista[];
  totalDia: number;
}

export const cierreCajaService = {
  async getReporte(fechaInicio?: string, fechaFin?: string): Promise<CierreCajaDia[]> {
    const params = new URLSearchParams();
    if (fechaInicio) params.append('fechaInicio', fechaInicio);
    if (fechaFin) params.append('fechaFin', fechaFin);
    
    const queryString = params.toString();
    const url = `/ventas/reporte/cierre-caja${queryString ? `?${queryString}` : ''}`;
    
    const response = await api.get<CierreCajaDia[]>(url);
    return response.data;
  },
};
