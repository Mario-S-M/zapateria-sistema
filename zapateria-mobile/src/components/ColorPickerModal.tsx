import React, { useState } from "react";
import { Modal, ScrollView } from "react-native";
import { YStack, XStack, Text, Button, Input } from "tamagui";
import { MaterialIcons } from "@expo/vector-icons";
import { colorService } from "../services/color.service";
import { toast } from "sonner-native";

interface ColorPickerModalProps {
  visible: boolean;
  onClose: () => void;
  onColorCreated: () => void;
}

export const ColorPickerModal: React.FC<ColorPickerModalProps> = ({
  visible,
  onClose,
  onColorCreated,
}) => {
  const [selectedColor, setSelectedColor] = useState("#FF6B6B");
  const [colorName, setColorName] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleCreateColor = async () => {
    if (!colorName.trim()) {
      toast.error("Por favor ingresa el nombre del color");
      return;
    }

    setIsLoading(true);
    try {
      const hexColor = selectedColor.startsWith("#")
        ? selectedColor
        : `#${selectedColor}`;

      await colorService.create({
        nombre: colorName.trim(),
        hexadecimal: hexColor,
        isCombo: false,
      });

      toast.success(`Color "${colorName}" creado exitosamente`);
      setColorName("");
      setSelectedColor("#FF6B6B");
      onColorCreated();
      onClose();
    } catch (error) {
      console.error("Error creating color:", error);
      toast.error("Error al crear el color");
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
              Crear Color
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
            {/* Paleta de colores predefinidos */}
            <YStack gap="$2">
              <Text fontSize="$4" fontWeight="600">
                Colores Sugeridos
              </Text>
              <YStack gap="$2">
                {[
                  { name: "Rojo Fuego", hex: "#FF3B30" },
                  { name: "Naranja", hex: "#FF9500" },
                  { name: "Amarillo", hex: "#FFCC00" },
                  { name: "Verde", hex: "#34C759" },
                  { name: "Azul Cielo", hex: "#30B0C0" },
                  { name: "Azul Marino", hex: "#0A84FF" },
                  { name: "Púrpura", hex: "#AF52DE" },
                  { name: "Rosa", hex: "#FF2D55" },
                  { name: "Blanco", hex: "#FFFFFF" },
                  { name: "Gris", hex: "#808080" },
                  { name: "Negro", hex: "#000000" },
                  { name: "Marrón", hex: "#8B4513" },
                ].map((color) => (
                  <Button
                    key={color.hex}
                    onPress={() => setSelectedColor(color.hex)}
                    backgroundColor={selectedColor === color.hex ? "$blue9" : "$gray3"}
                    borderWidth={2}
                    borderColor={selectedColor === color.hex ? "$blue11" : "$gray6"}
                    padding="$3"
                    borderRadius="$3"
                  >
                    <XStack gap="$3" alignItems="center" width="100%">
                      <YStack
                        width={40}
                        height={40}
                        borderRadius="$3"
                        backgroundColor={color.hex}
                        borderWidth={1}
                        borderColor="$gray6"
                      />
                      <YStack flex={1}>
                        <Text
                          fontWeight={selectedColor === color.hex ? "600" : "500"}
                          color={selectedColor === color.hex ? "white" : "black"}
                        >
                          {color.name}
                        </Text>
                        <Text
                          fontSize="$2"
                          color={selectedColor === color.hex ? "$gray2" : "$gray10"}
                        >
                          {color.hex}
                        </Text>
                      </YStack>
                      {selectedColor === color.hex && (
                        <MaterialIcons name="check" size={24} color="white" />
                      )}
                    </XStack>
                  </Button>
                ))}
              </YStack>
            </YStack>

            {/* Divider */}
            <YStack height={1} backgroundColor="$gray6" />

            {/* Custom color input */}
            <YStack gap="$2">
              <Text fontSize="$4" fontWeight="600">
                Código Personalizado
              </Text>
              <Input
                value={selectedColor}
                onChangeText={setSelectedColor}
                placeholder="#FF6B6B"
                backgroundColor="$gray2"
                borderColor="$gray6"
                padding="$3"
                borderRadius="$3"
              />
              <YStack
                padding="$3"
                backgroundColor={selectedColor}
                borderRadius="$3"
                borderWidth={1}
                borderColor="$gray6"
                height={60}
              />
            </YStack>

            {/* Color Name Input */}
            <YStack gap="$2">
              <Text fontSize="$4" fontWeight="600">
                Nombre del Color *
              </Text>
              <Input
                value={colorName}
                onChangeText={setColorName}
                placeholder="Ej: Mi Color Personalizado"
                backgroundColor="$gray2"
                borderColor="$gray6"
                padding="$3"
                borderRadius="$3"
              />
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
            onPress={handleCreateColor}
            disabled={isLoading || !colorName.trim()}
          >
            <Text fontWeight="700" color="white">
              {isLoading ? "Creando..." : "Crear Color"}
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

export default ColorPickerModal;
