import React, { useState } from "react";
import { Modal, ScrollView } from "react-native";
import { YStack, XStack, Text, Button, Input } from "tamagui";
import { MaterialIcons } from "@expo/vector-icons";
import { categoriaService } from "../services/categoria.service";
import { toast } from "sonner-native";

interface CategoryPickerModalProps {
  visible: boolean;
  onClose: () => void;
  onCategoryCreated: () => void;
}

export const CategoryPickerModal: React.FC<CategoryPickerModalProps> = ({
  visible,
  onClose,
  onCategoryCreated,
}) => {
  const [categoryName, setCategoryName] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleCreateCategory = async () => {
    if (!categoryName.trim()) {
      toast.error("Por favor ingresa el nombre de la categoría");
      return;
    }

    setIsLoading(true);
    try {
      await categoriaService.create({
        nombre: categoryName.trim(),
      });

      toast.success(`Categoría "${categoryName}" creada exitosamente`);
      setCategoryName("");
      onCategoryCreated();
      onClose();
    } catch (error) {
      console.error("Error creating category:", error);
      toast.error("Error al crear la categoría");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={false}
      onRequestClose={onClose}
    >
      <YStack flex={1} backgroundColor="white">
        {/* Header */}
        <YStack
          paddingHorizontal="$4"
          paddingVertical="$4"
          borderBottomWidth={1}
          borderBottomColor="$gray6"
        >
          <XStack justifyContent="space-between" alignItems="center">
            <Text fontSize="$6" fontWeight="700" color="black">
              Nueva Categoría
            </Text>
            <Button
              size="$3"
              circular
              onPress={onClose}
              backgroundColor="$gray3"
            >
              <MaterialIcons name="close" size={24} color="black" />
            </Button>
          </XStack>
        </YStack>

        {/* Content */}
        <ScrollView contentContainerStyle={{ padding: 16 }}>
          <YStack gap="$4">
            {/* Icon */}
            <YStack
              padding="$4"
              backgroundColor="$gray2"
              borderRadius="$4"
              alignItems="center"
            >
              <MaterialIcons name="category" size={64} color="$gray11" />
            </YStack>

            {/* Category Name Input */}
            <YStack gap="$2">
              <Text fontSize="$4" fontWeight="600">
                Nombre de la Categoría *
              </Text>
              <Input
                value={categoryName}
                onChangeText={setCategoryName}
                placeholder="Ej: Deportivos, Casuales, Formales"
                backgroundColor="$gray2"
                borderColor="$gray6"
                padding="$3"
                borderRadius="$3"
                fontSize="$4"
              />
            </YStack>

            {/* Suggestions */}
            <YStack
              padding="$3"
              backgroundColor="$gray2"
              borderRadius="$3"
              gap="$2"
            >
              <Text fontSize="$2" fontWeight="600">
                Ejemplos de categorías:
              </Text>
              <Text fontSize="$2">
                • Deportivos{"\n"}
                • Casuales{"\n"}
                • Formales{"\n"}
                • Sandalias{"\n"}
                • Botas{"\n"}
                • Tacones
              </Text>
            </YStack>
          </YStack>
        </ScrollView>

        {/* Buttons */}
        <YStack
          paddingHorizontal="$4"
          paddingVertical="$4"
          borderTopWidth={1}
          borderTopColor="$gray6"
          gap="$2"
        >
          <Button
            backgroundColor="$blue10"
            pressStyle={{ backgroundColor: "$blue11" }}
            onPress={handleCreateCategory}
            disabled={isLoading || !categoryName.trim()}
          >
            <Text fontWeight="700" color="white">
              {isLoading ? "Creando..." : "Crear Categoría"}
            </Text>
          </Button>
          <Button
            backgroundColor="$gray3"
            pressStyle={{ backgroundColor: "$gray4" }}
            onPress={onClose}
          >
            <Text fontWeight="700" color="black">
              Cancelar
            </Text>
          </Button>
        </YStack>
      </YStack>
    </Modal>
  );
};

export default CategoryPickerModal;
