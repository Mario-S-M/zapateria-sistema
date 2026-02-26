import api from '../lib/api';
import { Zapato } from '../types';

export interface CreateZapatoDto {
  codigoBarras: string;
  nombre: string;
  modelo: string;
  foto: string;
  precioCompra: number;
  precioPublico: number;
  medidaInicio: number;
  medidaFin: number;
  colorIds: string[];
  categoriaId?: string;
  inversionistaId?: string;
}

export const zapatoService = {
  getAll: async (): Promise<Zapato[]> => {
    const response = await api.get('/zapatos');
    return response.data;
  },

  getOne: async (id: string): Promise<Zapato> => {
    const response = await api.get(`/zapatos/${id}`);
    return response.data;
  },

  getByCodigoBarras: async (codigoBarras: string): Promise<Zapato> => {
    const response = await api.get(`/zapatos/codigo/${codigoBarras}`);
    return response.data;
  },

  create: async (data: CreateZapatoDto): Promise<Zapato> => {
    const response = await api.post('/zapatos', data);
    return response.data;
  },

  update: async (id: string, data: Partial<CreateZapatoDto>): Promise<Zapato> => {
    const response = await api.put(`/zapatos/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/zapatos/${id}`);
  },
};
