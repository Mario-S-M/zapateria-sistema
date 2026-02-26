import api from '../lib/api';
import { Venta, TipoPrecio } from '../types';

export interface VentaItemDto {
  zapatoId: string;
  cantidad: number;
  precioUnitario: number;
}

export interface CreateVentaDto {
  folio: string;
  tipoPrecio: TipoPrecio;
  inversionistaId?: string;
  items: VentaItemDto[];
}

export interface UpdateVentaDto {
  folio?: string;
  tipoPrecio?: TipoPrecio;
  inversionistaId?: string;
  items?: VentaItemDto[];
}

export const ventaService = {
  getAll: async (): Promise<Venta[]> => {
    const response = await api.get('/ventas');
    return response.data;
  },

  getOne: async (id: string): Promise<Venta> => {
    const response = await api.get(`/ventas/${id}`);
    return response.data;
  },

  create: async (data: CreateVentaDto): Promise<Venta> => {
    const response = await api.post('/ventas', data);
    return response.data;
  },

  update: async (id: string, data: UpdateVentaDto): Promise<Venta> => {
    const response = await api.put(`/ventas/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/ventas/${id}`);
  },
};
