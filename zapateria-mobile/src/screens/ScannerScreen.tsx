import React, { useState, useEffect } from "react";
import { StyleSheet } from "react-native";
import { CameraView, Camera } from "expo-camera";
import { YStack, XStack, Text, Button } from "tamagui";
import { toast } from "sonner-native";
import { zapatoService } from "../services/zapato.service";
import { useCartStore } from "../store/cart";
import { TipoPrecio } from "../types";
import { parsePrice } from "../utils/priceUtils";

export default function ScannerScreen() {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scanned, setScanned] = useState(false);
  const { addItem, tipoPrecio } = useCartStore();

  useEffect(() => {
    const getCameraPermissions = async () => {
      const { status } = await Camera.requestCameraPermissionsAsync();
      setHasPermission(status === "granted");
    };

    getCameraPermissions();
  }, []);

  const handleBarCodeScanned = async ({
    data,
  }: {
    type: string;
    data: string;
  }) => {
    setScanned(true);

    try {
      const zapato = await zapatoService.getByCodigoBarras(data);

      // Convertir precios a números de manera segura
      const precioPublico = parsePrice(zapato.precioPublico);
      const precioCompra = parsePrice(zapato.precioCompra);

      // Validar que los precios sean válidos
      if (precioPublico <= 0) {
        toast.error("Zapato sin precio configurado");
        return;
      }

      let precio = precioPublico;
      if (tipoPrecio === TipoPrecio.MAYORISTA && precioCompra > 0) {
        precio = precioCompra * 1.3;
      } else if (tipoPrecio === TipoPrecio.INVERSIONISTA && precioCompra > 0) {
        precio = precioCompra * 1.2;
      }

      addItem(zapato, 1, precio);
      toast.success(`${zapato.nombre} agregado al carrito`);
    } catch (error) {
      console.error("Error al escanear:", error);
      toast.error("Zapato no encontrado");
    }

    setTimeout(() => setScanned(false), 2000);
  };

  if (hasPermission === null) {
    return (
      <YStack flex={1} justifyContent="center" alignItems="center">
        <Text>Solicitando permiso de cámara...</Text>
      </YStack>
    );
  }

  if (hasPermission === false) {
    return (
      <YStack flex={1} justifyContent="center" alignItems="center" padding="$4">
        <Text textAlign="center">
          No se pudo acceder a la cámara. Verifica los permisos.
        </Text>
      </YStack>
    );
  }

  return (
    <YStack flex={1}>
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
      <YStack
        position="absolute"
        bottom="$4"
        left="$4"
        right="$4"
        backgroundColor="rgba(0,0,0,0.7)"
        padding="$4"
        borderRadius="$4"
      >
        <Text color="white" textAlign="center">
          {scanned ? "Procesando..." : "Escanea el código de barras"}
        </Text>
        {scanned && (
          <Button marginTop="$2" onPress={() => setScanned(false)}>
            Escanear de nuevo
          </Button>
        )}
      </YStack>
    </YStack>
  );
}
