import React, { useState } from "react";
import { Alert } from "react-native";
import * as ImagePicker from "expo-image-picker";
import { YStack, Button, XStack, Text } from "tamagui";
import { Ionicons } from "@expo/vector-icons";
import { uploadService } from "../services/upload.service";

interface ImagePickerComponentProps {
  onImageSelected: (imageUri: string) => void;
  disabled?: boolean;
}

export const ImagePickerComponent: React.FC<ImagePickerComponentProps> = ({
  onImageSelected,
  disabled = false,
}) => {
  const [uploading, setUploading] = useState(false);

  const uploadImage = async (imageUri: string) => {
    try {
      setUploading(true);
      const uploadedImageUrl = await uploadService.uploadZapatoImage(imageUri);
      onImageSelected(uploadedImageUrl);
      Alert.alert("Éxito", "Imagen subida exitosamente");
    } catch (error: any) {
      console.error("Error uploading image:", error);
      
      let errorMessage = "No se pudo subir la imagen. Intenta de nuevo.";
      if (error.message) {
        errorMessage = error.message;
      }
      
      Alert.alert(
        "Error",
        errorMessage
      );
    } finally {
      setUploading(false);
    }
  };

  const requestPermissions = async () => {
    const { status: cameraStatus } = await ImagePicker.requestCameraPermissionsAsync();
    const { status: mediaStatus } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    
    if (cameraStatus !== 'granted' || mediaStatus !== 'granted') {
      Alert.alert(
        "Permisos requeridos",
        "Necesitamos permisos de cámara y galería para esta funcionalidad.",
        [{ text: "OK" }]
      );
      return false;
    }
    return true;
  };

  const showImagePicker = () => {
    Alert.alert(
      "Seleccionar Imagen",
      "¿De dónde quieres obtener la imagen?",
      [
        {
          text: "Cancelar",
          style: "cancel",
        },
        {
          text: "Cámara",
          onPress: openCamera,
        },
        {
          text: "Galería",
          onPress: openGallery,
        },
      ]
    );
  };

  const openCamera = async () => {
    const hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      const result = await ImagePicker.launchCameraAsync({
        mediaTypes: 'images',
        allowsEditing: true,
        aspect: [1, 1], // Aspecto cuadrado para zapatos
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        await uploadImage(result.assets[0].uri);
      }
    } catch (error) {
      Alert.alert("Error", "No se pudo acceder a la cámara");
    }
  };

  const openGallery = async () => {
    const hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: 'images',
        allowsEditing: true,
        aspect: [1, 1], // Aspecto cuadrado para zapatos
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        await uploadImage(result.assets[0].uri);
      }
    } catch (error) {
      Alert.alert("Error", "No se pudo acceder a la galería");
    }
  };

  return (
    <YStack gap="$2">
      <Button
        onPress={showImagePicker}
        disabled={disabled || uploading}
        backgroundColor="$blue10"
        color="$white1"
        pressStyle={{ backgroundColor: "$blue11" }}
        disabledStyle={{ backgroundColor: "$gray6" }}
      >
        <XStack alignItems="center" gap="$2">
          <Ionicons 
            name={uploading ? "cloud-upload-outline" : "camera-outline"} 
            size={16} 
            color="white" 
          />
          <Text color="$white1" fontWeight="600">
            {uploading ? "Subiendo imagen..." : "Seleccionar Imagen"}
          </Text>
        </XStack>
      </Button>
    </YStack>
  );
};