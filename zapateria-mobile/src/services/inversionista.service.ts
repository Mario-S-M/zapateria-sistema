import api from '../lib/api';
import { Inversionista } from '../types';

export interface CreateInversionistaDto {
  nombre: string;
  telefono?: string;
  email?: string;
  activo?: boolean;
}

export const inversionistaService = {
  getAll: async (): Promise<Inversionista[]> => {
    const response = await api.get('/inversionistas');
    return response.data;
  },

  getActivos: async (): Promise<Inversionista[]> => {
    const response = await api.get('/inversionistas/activos');
    return response.data;
  },

  getOne: async (id: string): Promise<Inversionista> => {
    const response = await api.get(`/inversionistas/${id}`);
    return response.data;
  },

  create: async (data: CreateInversionistaDto): Promise<Inversionista> => {
    const response = await api.post('/inversionistas', data);
    return response.data;
  },

  update: async (id: string, data: Partial<CreateInversionistaDto>): Promise<Inversionista> => {
    const response = await api.put(`/inversionistas/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/inversionistas/${id}`);
  },
};
