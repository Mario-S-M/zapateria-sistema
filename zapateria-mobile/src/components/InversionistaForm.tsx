import React, { useState, useEffect } from "react";
import { ScrollView, Dimensions } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Button,
  Input,
  Card,
  H5,
} from "tamagui";
import { Inversionista } from "../types";

const { height: screenHeight } = Dimensions.get("window");

interface InversionistaFormProps {
  initialInversionista?: Inversionista | null;
  onSave: (inversionistaData: Omit<Inversionista, "id" | "createdAt" | "updatedAt">) => void;
  onCancel: () => void;
}

export const InversionistaForm: React.FC<InversionistaFormProps> = ({
  initialInversionista,
  onSave,
  onCancel,
}) => {
  const [nombre, setNombre] = useState(initialInversionista?.nombre || "");

  // Actualizar estados cuando cambia initialInversionista
  useEffect(() => {
    if (initialInversionista) {
      setNombre(initialInversionista.nombre || "");
    } else {
      // Reset para nuevo inversionista
      setNombre("");
    }
  }, [initialInversionista]);

  const handleSave = () => {
    // Validación básica
    if (!nombre.trim()) {
      return;
    }

    const inversionistaData = {
      nombre: nombre.trim(),
      activo: true, // Siempre activo
    };

    onSave(inversionistaData);
  };

  return (
    <YStack flex={1} height={screenHeight * 0.85}>
      <YStack padding="$4" paddingBottom="$2" backgroundColor="$background">
        <H5 textAlign="center">
          {initialInversionista ? "Editar Inversionista" : "Nuevo Inversionista"}
        </H5>
      </YStack>

      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{
          paddingHorizontal: 16,
          paddingBottom: 20,
          minHeight: 400,
        }}
        showsVerticalScrollIndicator={true}
        bounces={true}
      >
        <YStack gap="$4" paddingVertical="$3">
          {/* Información del inversionista */}
          <Card padding="$4" backgroundColor="$gray1" borderWidth={1} borderColor="$gray6">
            <YStack gap="$4">
              <Text fontSize="$4" fontWeight="bold" color="$gray12">
                Información del Inversionista
              </Text>

              <YStack gap="$2">
                <Text fontWeight="600" color="$gray11">Nombre Completo *</Text>
                <Input
                  value={nombre}
                  onChangeText={setNombre}
                  placeholder="Ingrese el nombre completo"
                  size="$4"
                  backgroundColor="$background"
                  borderColor="$gray7"
                  focusStyle={{ borderColor: "$gray9" }}
                />
                {!nombre.trim() && (
                  <Text fontSize="$2" color="$red9">
                    El nombre es requerido
                  </Text>
                )}
              </YStack>
            </YStack>
          </Card>

          {/* Vista previa */}
          <Card padding="$4" backgroundColor="$gray2" borderWidth={1} borderColor="$gray6">
            <YStack gap="$3">
              <Text fontSize="$4" fontWeight="bold" color="$gray12">
                Resumen
              </Text>

              <YStack gap="$2">
                <XStack justifyContent="space-between">
                  <Text color="$gray10" fontWeight="500">Nombre:</Text>
                  <Text fontWeight="600" color="$gray12">{nombre || "Sin especificar"}</Text>
                </XStack>

                <XStack justifyContent="space-between">
                  <Text color="$gray10" fontWeight="500">Estado:</Text>
                  <Text color="$green9" fontWeight="600">
                    Activo
                  </Text>
                </XStack>
              </YStack>
            </YStack>
          </Card>
        </YStack>
      </ScrollView>

      {/* Botones de acción fijos */}
      <YStack
        padding="$4"
        paddingTop="$3"
        backgroundColor="$background"
        borderTopWidth={1}
        borderTopColor="$borderColor"
      >
        <XStack gap="$3">
          <Button 
            backgroundColor="$gray6" 
            color="$gray12"
            borderColor="$gray8"
            onPress={onCancel} 
            flex={1}
            pressStyle={{ backgroundColor: "$gray7" }}
            hoverStyle={{ backgroundColor: "$gray7" }}
          >
            Cancelar
          </Button>
          <Button
            backgroundColor="$gray12"
            color="$gray1"
            borderColor="$gray12"
            onPress={handleSave}
            flex={1}
            disabled={!nombre.trim()}
            pressStyle={{ backgroundColor: "$gray11" }}
            hoverStyle={{ backgroundColor: "$gray11" }}
            disabledStyle={{ backgroundColor: "$gray8" }}
          >
            {initialInversionista ? "Actualizar" : "Crear"} Inversionista
          </Button>
        </XStack>
      </YStack>
    </YStack>
  );
};