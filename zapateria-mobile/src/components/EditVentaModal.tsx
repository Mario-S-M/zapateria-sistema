import React, { useState, useEffect } from "react";
import { FlatList, Alert } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Card,
  Button,
  Input,
  Select,
  Sheet,
  Separator,
  Adapt,
} from "tamagui";
import { Ionicons } from "@expo/vector-icons";
import { toast } from "sonner-native";
import { Venta, Zapato, Inversionista, TipoPrecio } from "../types";
import { ventaService, VentaItemDto } from "../services/venta.service";
import { zapatoService } from "../services/zapato.service";
import { inversionistaService } from "../services/inversionista.service";
import { formatPrice } from "../utils/priceUtils";

interface EditVentaModalProps {
  venta: Venta | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: () => void;
}

interface EditableVentaItem extends VentaItemDto {
  id?: string;
  zapato?: Zapato;
}

export const EditVentaModal: React.FC<EditVentaModalProps> = ({
  venta,
  isOpen,
  onClose,
  onSave,
}) => {
  const [folio, setFolio] = useState("");
  const [tipoPrecio, setTipoPrecio] = useState<TipoPrecio>(TipoPrecio.MAYORISTA);
  const [inversionistaId, setInversionistaId] = useState<string>("");
  const [items, setItems] = useState<EditableVentaItem[]>([]);
  const [zapatos, setZapatos] = useState<Zapato[]>([]);
  const [inversionistas, setInversionistas] = useState<Inversionista[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (venta && isOpen) {
      setFolio(venta.folio);
      setTipoPrecio(venta.tipoPrecio);
      setInversionistaId(venta.inversionista?.id || "");
      setItems(
        venta.items.map(item => ({
          id: item.id,
          zapatoId: item.zapato?.id || "",
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
          zapato: item.zapato,
        }))
      );
    }
  }, [venta, isOpen]);

  useEffect(() => {
    if (isOpen) {
      loadData();
    }
  }, [isOpen]);

  const loadData = async () => {
    try {
      const [zapatosData, inversionistasData] = await Promise.all([
        zapatoService.getAll(),
        inversionistaService.getAll(),
      ]);
      setZapatos(zapatosData);
      setInversionistas(inversionistasData);
    } catch (error) {
      toast.error("Error al cargar datos");
    }
  };

  const addItem = () => {
    setItems([
      ...items,
      {
        zapatoId: "",
        cantidad: 1,
        precioUnitario: 0,
      },
    ]);
  };

  const removeItem = (index: number) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const updateItem = (index: number, field: keyof EditableVentaItem, value: any) => {
    const updatedItems = [...items];
    updatedItems[index] = { ...updatedItems[index], [field]: value };
    
    if (field === "zapatoId") {
      const selectedZapato = zapatos.find(z => z.id === value);
      if (selectedZapato) {
        updatedItems[index].zapato = selectedZapato;
        // Auto-set precio based on tipoPrecio
        const precio = selectedZapato.precioPublico; // For now, use public price
        updatedItems[index].precioUnitario = precio;
      }
    }
    
    setItems(updatedItems);
  };

  const calculateTotal = () => {
    return items.reduce((total, item) => total + (item.cantidad * item.precioUnitario), 0);
  };

  const handleSave = async () => {
    if (!venta) return;
    
    if (!folio.trim()) {
      toast.error("El folio es requerido");
      return;
    }

    if (items.length === 0) {
      toast.error("Debe haber al menos un item");
      return;
    }

    const invalidItems = items.filter(item => !item.zapatoId || item.cantidad <= 0);
    if (invalidItems.length > 0) {
      toast.error("Todos los items deben tener un zapato y cantidad válida");
      return;
    }

    setLoading(true);
    try {
      await ventaService.update(venta.id, {
        folio: folio.trim(),
        tipoPrecio,
        inversionistaId: inversionistaId || undefined,
        items: items.map(item => ({
          zapatoId: item.zapatoId,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
        })),
      });
      
      toast.success("Venta actualizada correctamente");
      onSave();
      onClose();
    } catch (error) {
      toast.error("Error al actualizar la venta");
    } finally {
      setLoading(false);
    }
  };

  const renderItem = ({ item, index }: { item: EditableVentaItem; index: number }) => (
    <Card padding="$3" marginBottom="$2">
      <YStack gap="$2">
        <XStack justifyContent="space-between" alignItems="center">
          <Text fontWeight="bold">Item {index + 1}</Text>
          <Button
            size="$2"
            circular
            backgroundColor="$red8"
            onPress={() => removeItem(index)}
          >
            <Ionicons name="trash" size={14} color="white" />
          </Button>
        </XStack>

        <Select
          value={item.zapatoId}
          onValueChange={(value) => updateItem(index, "zapatoId", value)}
        >
          <Select.Trigger>
            <Select.Value placeholder="Seleccionar zapato" />
          </Select.Trigger>
          <Adapt when="sm">
            <Sheet native modal dismissOnSnapToBottom>
              <Sheet.Frame>
                <Sheet.ScrollView>
                  <Adapt.Contents />
                </Sheet.ScrollView>
              </Sheet.Frame>
              <Sheet.Overlay />
            </Sheet>
          </Adapt>
          <Select.Content zIndex={200000}>
            <Select.ScrollUpButton />
            <Select.Viewport>
              {zapatos.map((zapato) => (
                <Select.Item key={zapato.id} value={zapato.id} index={zapatos.indexOf(zapato)}>
                  <Select.ItemText>{zapato.modelo}</Select.ItemText>
                </Select.Item>
              ))}
            </Select.Viewport>
            <Select.ScrollDownButton />
          </Select.Content>
        </Select>

        <XStack gap="$2" alignItems="center">
          <YStack flex={1}>
            <Text fontSize="$2">Cantidad</Text>
            <Input
              value={item.cantidad.toString()}
              onChangeText={(text) => updateItem(index, "cantidad", parseInt(text) || 0)}
              keyboardType="numeric"
            />
          </YStack>
          <YStack flex={1}>
            <Text fontSize="$2">Precio Unitario</Text>
            <Input
              value={item.precioUnitario.toString()}
              onChangeText={(text) => updateItem(index, "precioUnitario", parseFloat(text) || 0)}
              keyboardType="numeric"
            />
          </YStack>
        </XStack>

        <XStack justifyContent="space-between">
          <Text color="$gray10">Subtotal:</Text>
          <Text fontWeight="bold">${formatPrice(item.cantidad * item.precioUnitario)}</Text>
        </XStack>
      </YStack>
    </Card>
  );

  if (!venta) return null;

  return (
    <Sheet modal open={isOpen} onOpenChange={onClose}>
      <Sheet.Overlay />
      <Sheet.Frame>
        <Sheet.Handle />
        <YStack padding="$4" flex={1}>
          <Text fontSize="$6" fontWeight="bold" marginBottom="$4">Editar Venta</Text>

          <YStack gap="$3">
            <YStack>
              <Text fontSize="$3" marginBottom="$1">Folio</Text>
              <Input
                value={folio}
                onChangeText={setFolio}
                placeholder="Folio de la venta"
              />
            </YStack>

            <YStack>
              <Text fontSize="$3" marginBottom="$1">Tipo de Precio</Text>
              <Select value={tipoPrecio} onValueChange={(value) => setTipoPrecio(value as TipoPrecio)}>
                <Select.Trigger>
                  <Select.Value />
                </Select.Trigger>
                <Select.Content>
                  <Select.Item value={TipoPrecio.PUBLICO} index={0}>
                    <Select.ItemText>Público</Select.ItemText>
                  </Select.Item>
                  <Select.Item value={TipoPrecio.MAYORISTA} index={1}>
                    <Select.ItemText>Mayorista</Select.ItemText>
                  </Select.Item>
                  <Select.Item value={TipoPrecio.INVERSIONISTA} index={2}>
                    <Select.ItemText>Inversionista</Select.ItemText>
                  </Select.Item>
                </Select.Content>
              </Select>
            </YStack>

            <YStack>
              <Text fontSize="$3" marginBottom="$1">Inversionista (Opcional)</Text>
              <Select
                value={inversionistaId}
                onValueChange={setInversionistaId}
              >
                <Select.Trigger>
                  <Select.Value placeholder="Seleccionar inversionista" />
                </Select.Trigger>
                <Select.Content>
                  <Select.Item value="" index={0}>
                    <Select.ItemText>Sin inversionista</Select.ItemText>
                  </Select.Item>
                  {inversionistas.map((inv, idx) => (
                    <Select.Item key={inv.id} value={inv.id} index={idx + 1}>
                      <Select.ItemText>{inv.nombre}</Select.ItemText>
                    </Select.Item>
                  ))}
                </Select.Content>
              </Select>
            </YStack>
          </YStack>

          <Separator marginVertical="$4" />

          <XStack justifyContent="space-between" alignItems="center" marginBottom="$3">
            <Text fontSize="$4" fontWeight="bold">Items</Text>
            <Button onPress={addItem} backgroundColor="$green8">
              <Ionicons name="add" size={16} color="white" />
            </Button>
          </XStack>

          <FlatList
            data={items}
            renderItem={renderItem}
            keyExtractor={(_, index) => index.toString()}
            style={{ flex: 1 }}
          />

          <Separator marginVertical="$3" />

          <XStack justifyContent="space-between" alignItems="center" marginBottom="$4">
            <Text fontSize="$5" fontWeight="bold">Total:</Text>
            <Text fontSize="$6" fontWeight="bold" color="$green10">
              ${formatPrice(calculateTotal())}
            </Text>
          </XStack>

          <XStack gap="$3">
            <Button flex={1} onPress={onClose} backgroundColor="$gray8">
              Cancelar
            </Button>
            <Button
              flex={1}
              onPress={handleSave}
              backgroundColor="$blue8"
              disabled={loading}
            >
              {loading ? "Guardando..." : "Guardar"}
            </Button>
          </XStack>
        </YStack>
      </Sheet.Frame>
    </Sheet>
  );
};