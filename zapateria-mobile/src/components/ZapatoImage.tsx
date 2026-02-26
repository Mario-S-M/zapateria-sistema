import React, { useState } from "react";
import { Image, ImageStyle } from "react-native";
import { YStack, Text } from "tamagui";
import { Ionicons } from "@expo/vector-icons";

interface ZapatoImageProps {
  uri?: string;
  width?: number;
  height?: number;
  borderRadius?: number;
  showErrorText?: boolean;
}

export const ZapatoImage: React.FC<ZapatoImageProps> = ({
  uri,
  width = 80,
  height = 80,
  borderRadius = 8,
  showErrorText = false,
}) => {
  const [imageError, setImageError] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const imageStyle: ImageStyle = {
    width,
    height,
    borderRadius,
    backgroundColor: '#f3f4f6',
    borderWidth: 1,
    borderColor: '#e5e7eb',
  };

  const placeholderUri = `https://via.placeholder.com/${width}x${height}/e5e7eb/9ca3af?text=Sin+Foto`;

  // Función para validar URI de imagen
  const isValidImageUri = (uri: string | undefined): boolean => {
    if (!uri || uri.trim() === '') return false;
    
    // Verificar que sea una URL válida
    try {
      new URL(uri);
      return true;
    } catch {
      return false;
    }
  };

  // Si no hay URI válida o hubo error, mostrar placeholder
  if (!isValidImageUri(uri) || imageError) {
    return (
      <YStack
        width={width}
        height={height}
        borderRadius={borderRadius}
        backgroundColor="$gray4"
        borderWidth={1}
        borderColor="$gray6"
        alignItems="center"
        justifyContent="center"
        gap="$1"
      >
        <Ionicons name="image-outline" size={width * 0.3} color="#9ca3af" />
        {showErrorText && (
          <Text fontSize="$1" color="$gray10" textAlign="center">
            Sin Imagen
          </Text>
        )}
      </YStack>
    );
  }

  return (
    <Image 
      source={{ uri }}
      style={imageStyle}
      resizeMode="cover"
      onLoadStart={() => {
        setIsLoading(true);
        setImageError(false);
      }}
      onLoad={() => {
        setIsLoading(false);
        setImageError(false);
      }}
      onError={(error) => {
        setIsLoading(false);
        setImageError(true);
      }}
    />
  );
};