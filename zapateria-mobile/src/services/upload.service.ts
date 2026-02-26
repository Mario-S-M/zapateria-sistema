import api from '../lib/api';

export interface UploadImageResponse {
  message: string;
  filePath: string;
  originalName: string;
  size: number;
}

export const uploadService = {
  uploadZapatoImage: async (imageUri: string): Promise<string> => {
    try {
      // Crear FormData
      const formData = new FormData();
      
      // Obtener información del archivo
      const filename = imageUri.split('/').pop() || 'image.jpg';
      const match = /\.(\w+)$/.exec(filename);
      const type = match ? `image/${match[1]}` : 'image/jpeg';
      
      // Agregar el archivo al FormData (formato específico para React Native)
      const fileToUpload = {
        uri: imageUri,
        type: type,
        name: filename,
      };
      
      formData.append('image', fileToUpload as any);

      // Hacer la petición
      const response = await api.post<UploadImageResponse>('/upload/zapato-image', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      // Construir la URL completa de la imagen
      const baseUrl = api.defaults.baseURL || 'http://localhost:3000';
      // El backend ya retorna el path relativo (ej: uploads/filename.jpg)
      const imageUrl = `${baseUrl}/${response.data.filePath}`;
      
      return imageUrl;
    } catch (error: any) {
      console.error('Error subiendo imagen:', error);
      throw new Error(error.response?.data?.message || 'Error al subir la imagen');
    }
  }
};