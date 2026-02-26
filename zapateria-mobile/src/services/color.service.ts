import api from "../lib/api";
import { Color } from "../types";

export const colorService = {
  getAll: async (): Promise<Color[]> => {
    const response = await api.get("/colores");
    return response.data;
  },

  getOne: async (id: string): Promise<Color> => {
    const response = await api.get(`/colores/${id}`);
    return response.data;
  },

  create: async (data: {
    nombre: string;
    hexadecimal?: string;
    isCombo?: boolean;
    primaryColor?: string;
    secondaryColor?: string;
  }): Promise<Color> => {
    const response = await api.post("/colores", data);
    return response.data;
  },

  update: async (
    id: string,
    data: {
      nombre?: string;
      hexadecimal?: string;
      isCombo?: boolean;
      primaryColor?: string;
      secondaryColor?: string;
    }
  ): Promise<Color> => {
    const response = await api.put(`/colores/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/colores/${id}`);
  },
};
