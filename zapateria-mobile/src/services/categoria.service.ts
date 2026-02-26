import api from '../lib/api';
import { Categoria } from '../types';

export interface CreateCategoriaDto {
  nombre: string;
  activo?: boolean;
}

export interface UpdateCategoriaDto {
  nombre?: string;
  activo?: boolean;
}

export const categoriaService = {
  getAll: async (): Promise<Categoria[]> => {
    const response = await api.get('/categorias');
    return response.data;
  },

  getOne: async (id: string): Promise<Categoria> => {
    const response = await api.get(`/categorias/${id}`);
    return response.data;
  },

  create: async (data: CreateCategoriaDto): Promise<Categoria> => {
    const response = await api.post('/categorias', data);
    return response.data;
  },

  update: async (id: string, data: UpdateCategoriaDto): Promise<Categoria> => {
    const response = await api.put(`/categorias/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/categorias/${id}`);
  },
};