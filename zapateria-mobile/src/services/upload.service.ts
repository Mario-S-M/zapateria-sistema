import api from "../lib/api";

export interface UploadImageResponse {
  message: string;
  filePath: string;
  originalName: string;
  size: number;
}

export const uploadService = {
  uploadZapatoImage: async (imageUri: string): Promise<string> => {
    try {
      console.log("📦 Iniciando subida de imagen:", imageUri);
      // Crear FormData
      const formData = new FormData();

      // Obtener información del archivo
      const filename = imageUri.split("/").pop() || "image.jpg";
      const match = /\.(\w+)$/.exec(filename);
      const type = match ? `image/${match[1]}` : "image/jpeg";

      console.log("📄 Detalles del archivo:", { filename, type });

      // Agregar el archivo al FormData (formato específico para React Native)
      const fileToUpload = {
        uri: imageUri,
        type: type,
        name: filename,
      };

      formData.append("image", fileToUpload as any);

      // Hacer la petición
      console.log("🌐 Enviando petición POST a /upload/zapato-image");
      const response = await api.post<UploadImageResponse>(
        "/upload/zapato-image",
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        },
      );
      console.log("✅ Respuesta recibida:", response.status);

      // Construir la URL completa de la imagen
      const baseUrl = api.defaults.baseURL || "http://localhost:3000";
      // El backend ya retorna el path relativo (ej: uploads/filename.jpg)
      const imageUrl = `${baseUrl}/${response.data.filePath}`;

      console.log("🔗 URL final de la imagen:", imageUrl);
      return imageUrl;
    } catch (error: any) {
      console.error("❌ Error subiendo imagen:", error);
      console.error(
        "🔍 Detalles del error:",
        JSON.stringify(error.response?.data || error.message, null, 2),
      );
      throw new Error(
        error.response?.data?.message || "Error al subir la imagen",
      );
    }
  },
};
