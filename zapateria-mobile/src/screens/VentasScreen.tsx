import React, { useEffect, useState } from "react";
import { FlatList, RefreshControl, Alert } from "react-native";
import { YStack, Text, Card, H3, XStack, Separator, Button } from "tamagui";
import { Ionicons } from "@expo/vector-icons";
import { ventaService } from "../services/venta.service";
import { Venta } from "../types";
import { toast } from "sonner-native";
import { formatPrice } from "../utils/priceUtils";
import { EditVentaModal } from "../components/EditVentaModal";

export default function VentasScreen() {
  const [ventas, setVentas] = useState<Venta[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [editingVenta, setEditingVenta] = useState<Venta | null>(null);

  const loadVentas = async () => {
    try {
      const data = await ventaService.getAll();
      setVentas(data);
    } catch (error) {
      toast.error("Error al cargar ventas");
    }
  };

  useEffect(() => {
    loadVentas();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadVentas();
    setRefreshing(false);
  };

  const handleDeleteVenta = (venta: Venta) => {
    Alert.alert(
      "Eliminar Venta",
      `¿Estás seguro de que quieres eliminar la venta ${venta.folio}?`,
      [
        { text: "Cancelar", style: "cancel" },
        {
          text: "Eliminar",
          style: "destructive",
          onPress: () => deleteVenta(venta.id),
        },
      ]
    );
  };

  const deleteVenta = async (id: string) => {
    try {
      await ventaService.delete(id);
      toast.success("Venta eliminada correctamente");
      loadVentas();
    } catch (error) {
      toast.error("Error al eliminar la venta");
    }
  };

  const handleEditVenta = (venta: Venta) => {
    setEditingVenta(venta);
  };

  const renderItem = ({ item }: { item: Venta }) => (
    <Card marginVertical="$2" padding="$3">
      <XStack
        justifyContent="space-between"
        alignItems="center"
        marginBottom="$2"
      >
        <Text fontWeight="bold" fontSize="$5">
          {item.folio}
        </Text>
        <Text fontSize="$6" fontWeight="bold" color="$green10">
          ${formatPrice(item.total)}
        </Text>
      </XStack>

      <Separator marginBottom="$2" />

      <YStack gap="$1">
        <XStack justifyContent="space-between">
          <Text color="$gray10">Fecha:</Text>
          <Text>{new Date(item.fecha).toLocaleDateString()}</Text>
        </XStack>

        <XStack justifyContent="space-between">
          <Text color="$gray10">Tipo:</Text>
          <Text>{item.tipoPrecio}</Text>
        </XStack>

        {item.inversionista && (
          <XStack justifyContent="space-between">
            <Text color="$gray10">Inversionista:</Text>
            <Text>{item.inversionista.nombre}</Text>
          </XStack>
        )}

        <XStack justifyContent="space-between">
          <Text color="$gray10">Items:</Text>
          <Text>{item.items.length}</Text>
        </XStack>
      </YStack>

      <Separator marginVertical="$2" />

      <XStack justifyContent="flex-end" gap="$2">
        <Button
          size="$3"
          circular
          backgroundColor="$blue8"
          onPress={() => handleEditVenta(item)}
        >
          <Ionicons name="pencil" size={16} color="white" />
        </Button>
        <Button
          size="$3"
          circular
          backgroundColor="$red8"
          onPress={() => handleDeleteVenta(item)}
        >
          <Ionicons name="trash" size={16} color="white" />
        </Button>
      </XStack>
    </Card>
  );

  return (
    <YStack flex={1} padding="$4">
      <H3 marginBottom="$4">Ventas</H3>

      <FlatList
        data={ventas}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <YStack
            flex={1}
            justifyContent="center"
            alignItems="center"
            marginTop="$10"
          >
            <Text>No hay ventas registradas</Text>
          </YStack>
        }
      />

      <EditVentaModal
        venta={editingVenta}
        isOpen={!!editingVenta}
        onClose={() => setEditingVenta(null)}
        onSave={() => {
          loadVentas();
          setEditingVenta(null);
        }}
      />
    </YStack>
  );
}
