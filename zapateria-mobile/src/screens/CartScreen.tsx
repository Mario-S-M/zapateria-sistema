import React from "react";
import { FlatList } from "react-native";
import { YStack, XStack, Text, Button, Card, H3, Separator } from "tamagui";
import { useCartStore } from "../store/cart";
import { toast } from "sonner-native";
import { ventaService } from "../services/venta.service";
import { useNavigation } from "@react-navigation/native";
import { formatPrice } from "../utils/priceUtils";

export default function CartScreen() {
  const {
    items,
    removeItem,
    updateQuantity,
    clearCart,
    getTotal,
    tipoPrecio,
    inversionistaId,
  } = useCartStore();
  const navigation = useNavigation();

  const handleCheckout = async () => {
    if (items.length === 0) {
      toast.error("El carrito está vacío");
      return;
    }

    try {
      const folio = `V-${Date.now()}`;

      await ventaService.create({
        folio,
        tipoPrecio,
        inversionistaId,
        items: items.map((item) => ({
          zapatoId: item.zapato.id,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          inversionistaId: item.zapato.inversionistaId,
        })),
      });

      toast.success("Venta registrada exitosamente");
      clearCart();
      navigation.navigate("Ventas" as never);
    } catch (error) {
      toast.error("Error al registrar la venta");
    }
  };

  const renderItem = ({ item }: any) => (
    <Card marginVertical="$2" padding="$3">
      <XStack justifyContent="space-between" alignItems="center">
        <YStack flex={1}>
          <Text fontWeight="bold">{item.zapato.nombre}</Text>
          <Text fontSize="$2" color="$gray10">
            {item.zapato.modelo}
          </Text>
          <Text fontSize="$3" color="$blue10">
            ${formatPrice(item.precioUnitario)}
          </Text>
        </YStack>

        <XStack gap="$2" alignItems="center">
          <Button
            size="$2"
            onPress={() =>
              updateQuantity(item.zapato.id, Math.max(1, item.cantidad - 1))
            }
          >
            -
          </Button>
          <Text>{item.cantidad}</Text>
          <Button
            size="$2"
            onPress={() => updateQuantity(item.zapato.id, item.cantidad + 1)}
          >
            +
          </Button>
          <Button
            size="$2"
            theme="red"
            onPress={() => removeItem(item.zapato.id)}
          >
            Eliminar
          </Button>
        </XStack>
      </XStack>

      <Separator marginVertical="$2" />

      <Text textAlign="right" fontWeight="bold">
        Subtotal: ${formatPrice((item.precioUnitario || 0) * item.cantidad)}
      </Text>
    </Card>
  );

  return (
    <YStack flex={1} padding="$4">
      <H3 marginBottom="$4">Carrito de Compras</H3>

      {items.length === 0 ? (
        <YStack flex={1} justifyContent="center" alignItems="center">
          <Text>El carrito está vacío</Text>
        </YStack>
      ) : (
        <>
          <FlatList
            data={items}
            renderItem={renderItem}
            keyExtractor={(item) => item.zapato.id}
            style={{ flex: 1 }}
          />

          <YStack padding="$4" backgroundColor="$background" gap="$2">
            <XStack justifyContent="space-between">
              <Text fontSize="$5">Tipo de Precio:</Text>
              <Text fontSize="$5" fontWeight="bold">
                {tipoPrecio}
              </Text>
            </XStack>

            <Separator />

            <XStack justifyContent="space-between">
              <Text fontSize="$6" fontWeight="bold">
                Total:
              </Text>
              <Text fontSize="$6" fontWeight="bold" color="$green10">
                ${formatPrice(getTotal())}
              </Text>
            </XStack>

            <Button
              size="$5"
              theme="blue"
              marginTop="$2"
              onPress={handleCheckout}
            >
              Finalizar Venta
            </Button>
          </YStack>
        </>
      )}
    </YStack>
  );
}
