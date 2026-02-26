import React, { useState, useEffect } from "react";
import { StyleSheet, Modal } from "react-native";
import { CameraView, Camera } from "expo-camera";
import { YStack, XStack, Text, Button } from "tamagui";
import { MaterialIcons } from "@expo/vector-icons";

interface BarcodeScannerProps {
  visible: boolean;
  onClose: () => void;
  onScan: (barcode: string) => void;
}

export const BarcodeScanner: React.FC<BarcodeScannerProps> = ({
  visible,
  onClose,
  onScan,
}) => {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scanned, setScanned] = useState(false);

  useEffect(() => {
    if (visible) {
      getCameraPermissions();
      setScanned(false);
    }
  }, [visible]);

  const getCameraPermissions = async () => {
    const { status } = await Camera.requestCameraPermissionsAsync();
    setHasPermission(status === "granted");
  };

  const handleBarCodeScanned = ({ data }: { type: string; data: string }) => {
    if (scanned) return;

    setScanned(true);
    onScan(data);
    
    // Cerrar el scanner después de escanear
    setTimeout(() => {
      onClose();
    }, 500);
  };

  if (!visible) return null;

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={false}
      onRequestClose={onClose}
    >
      <YStack flex={1} backgroundColor="$gray1">
        {hasPermission === null ? (
          <YStack flex={1} justifyContent="center" alignItems="center" padding="$4">
            <Text fontSize="$5" color="$gray11">
              Solicitando permiso de cámara...
            </Text>
          </YStack>
        ) : hasPermission === false ? (
          <YStack flex={1} justifyContent="center" alignItems="center" padding="$4">
            <Text fontSize="$5" color="$gray11" textAlign="center" marginBottom="$4">
              No se pudo acceder a la cámara. Verifica los permisos en la configuración.
            </Text>
            <Button onPress={onClose} theme="red">
              Cerrar
            </Button>
          </YStack>
        ) : (
          <>
            <CameraView
              style={StyleSheet.absoluteFillObject}
              facing="back"
              onBarcodeScanned={scanned ? undefined : handleBarCodeScanned}
              barcodeScannerSettings={{
                barcodeTypes: [
                  "qr",
                  "pdf417",
                  "code128",
                  "code39",
                  "ean13",
                  "ean8",
                  "upc_a",
                  "upc_e",
                ],
              }}
            />

            {/* Header con botón de cerrar */}
            <YStack
              position="absolute"
              top={0}
              left={0}
              right={0}
              backgroundColor="rgba(0,0,0,0.7)"
              padding="$4"
              paddingTop="$6"
            >
              <XStack justifyContent="space-between" alignItems="center">
                <Text color="white" fontSize="$6" fontWeight="600">
                  Escanear Código de Barras
                </Text>
                <Button
                  size="$3"
                  circular
                  onPress={onClose}
                  backgroundColor="rgba(255,255,255,0.3)"
                  pressStyle={{ backgroundColor: "rgba(255,255,255,0.5)" }}
                >
                  <MaterialIcons name="close" size={24} color="white" />
                </Button>
              </XStack>
            </YStack>

            {/* Marco de escaneo */}
            <YStack
              position="absolute"
              top="35%"
              left="10%"
              right="10%"
              height={200}
              borderWidth={3}
              borderColor="white"
              borderRadius="$4"
              borderStyle="dashed"
            />

            {/* Instrucciones */}
            <YStack
              position="absolute"
              bottom="$6"
              left="$4"
              right="$4"
              backgroundColor="rgba(0,0,0,0.7)"
              padding="$4"
              borderRadius="$4"
              alignItems="center"
            >
              <MaterialIcons name="center-focus-strong" size={40} color="white" style={{ marginBottom: 8 }} />
              <Text color="white" textAlign="center" fontSize="$5" fontWeight="600">
                {scanned ? "✓ Código escaneado" : "Coloca el código dentro del marco"}
              </Text>
              <Text color="white" textAlign="center" fontSize="$3" marginTop="$2" opacity={0.8}>
                {scanned
                  ? "Procesando..."
                  : "El escáner detectará automáticamente el código"}
              </Text>
              {scanned && (
                <Button
                  marginTop="$3"
                  onPress={() => setScanned(false)}
                  theme="blue"
                >
                  Escanear de nuevo
                </Button>
              )}
            </YStack>
          </>
        )}
      </YStack>
    </Modal>
  );
};
