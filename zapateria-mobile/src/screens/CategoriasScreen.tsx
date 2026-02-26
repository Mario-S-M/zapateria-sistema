import React, { useEffect, useState } from "react";
import { FlatList, RefreshControl, Alert } from "react-native";
import { YStack, Text, Card, H3, XStack, Button, Input, Dialog, Adapt, Sheet } from "tamagui";
import { Ionicons } from "@expo/vector-icons";
import { categoriaService, CreateCategoriaDto, UpdateCategoriaDto } from "../services/categoria.service";
import { Categoria } from "../types";
import { toast } from "sonner-native";

export default function CategoriasScreen() {
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editingCategoria, setEditingCategoria] = useState<Categoria | null>(null);
  const [nombre, setNombre] = useState("");
  const [loading, setLoading] = useState(false);

  const loadCategorias = async () => {
    try {
      const data = await categoriaService.getAll();
      setCategorias(data);
    } catch (error) {
      toast.error("Error al cargar categorías");
    }
  };

  useEffect(() => {
    loadCategorias();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await loadCategorias();
    setRefreshing(false);
  };

  const handleOpenModal = (categoria?: Categoria) => {
    if (categoria) {
      setEditingCategoria(categoria);
      setNombre(categoria.nombre);
    } else {
      setEditingCategoria(null);
      setNombre("");
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingCategoria(null);
    setNombre("");
    setLoading(false);
  };

  const handleSave = async () => {
    if (!nombre.trim()) {
      toast.error("El nombre es requerido");
      return;
    }

    setLoading(true);
    try {
      if (editingCategoria) {
        const updateData: UpdateCategoriaDto = {
          nombre: nombre.trim(),
        };
        await categoriaService.update(editingCategoria.id, updateData);
        toast.success("Categoría actualizada correctamente");
      } else {
        const createData: CreateCategoriaDto = {
          nombre: nombre.trim(),
        };
        await categoriaService.create(createData);
        toast.success("Categoría creada correctamente");
      }
      
      await loadCategorias();
      handleCloseModal();
    } catch (error) {
      toast.error("Error al guardar la categoría");
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCategoria = (categoria: Categoria) => {
    Alert.alert(
      "Eliminar Categoría",
      `¿Estás seguro de que quieres eliminar la categoría "${categoria.nombre}"?`,
      [
        { text: "Cancelar", style: "cancel" },
        {
          text: "Eliminar",
          style: "destructive",
          onPress: () => deleteCategoria(categoria.id),
        },
      ]
    );
  };

  const deleteCategoria = async (id: string) => {
    try {
      await categoriaService.delete(id);
      toast.success("Categoría eliminada correctamente");
      loadCategorias();
    } catch (error) {
      toast.error("Error al eliminar la categoría");
    }
  };

  const renderItem = ({ item }: { item: Categoria }) => (
    <Card marginVertical="$2" padding="$3">
      <XStack justifyContent="space-between" alignItems="flex-start" marginBottom="$2">
        <YStack flex={1}>
          <Text fontWeight="bold" fontSize="$5" marginBottom="$1">
            {item.nombre}
          </Text>
        </YStack>
        
        <XStack gap="$2" marginLeft="$3">
          <Button
            size="$3"
            circular
            backgroundColor="$blue8"
            onPress={() => handleOpenModal(item)}
          >
            <Ionicons name="pencil" size={16} color="white" />
          </Button>
          <Button
            size="$3"
            circular
            backgroundColor="$red8"
            onPress={() => handleDeleteCategoria(item)}
          >
            <Ionicons name="trash" size={16} color="white" />
          </Button>
        </XStack>
      </XStack>

      <XStack justifyContent="space-between" alignItems="center">
        <Text fontSize="$2" color="$gray9">
          Creada: {new Date(item.createdAt).toLocaleDateString()}
        </Text>
        <XStack alignItems="center" gap="$1">
          <Ionicons 
            name={item.activo ? "checkmark-circle" : "close-circle"} 
            size={16} 
            color={item.activo ? "green" : "red"} 
          />
          <Text fontSize="$2" color={item.activo ? "$green10" : "$red10"}>
            {item.activo ? "Activa" : "Inactiva"}
          </Text>
        </XStack>
      </XStack>
    </Card>
  );

  return (
    <YStack flex={1} padding="$4">
      <XStack justifyContent="space-between" alignItems="center" marginBottom="$4">
        <H3>Categorías</H3>
        <Button
          backgroundColor="$green8"
          onPress={() => handleOpenModal()}
        >
          <Ionicons name="add" size={20} color="white" />
        </Button>
      </XStack>

      <FlatList
        data={categorias}
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
            <Text>No hay categorías registradas</Text>
          </YStack>
        }
      />

      <Dialog modal open={showModal} onOpenChange={setShowModal}>
        <Adapt when="sm">
          <Sheet animation="medium" zIndex={200000} modal dismissOnSnapToBottom>
            <Sheet.Frame padding="$4" gap="$4">
              <Adapt.Contents />
            </Sheet.Frame>
            <Sheet.Overlay />
          </Sheet>
        </Adapt>

        <Dialog.Portal>
          <Dialog.Overlay />
          <Dialog.Content
            bordered
            elevate
            key="content"
            animateOnly={['transform', 'opacity']}
            animation={[
              'quicker',
              {
                opacity: {
                  overshootClamping: true,
                },
              },
            ]}
            enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
            exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
            gap="$4"
          >
            <Dialog.Title>
              {editingCategoria ? "Editar Categoría" : "Nueva Categoría"}
            </Dialog.Title>

            <YStack gap="$3">
              <YStack>
                <Text fontSize="$3" marginBottom="$1">Nombre *</Text>
                <Input
                  value={nombre}
                  onChangeText={setNombre}
                  placeholder="Nombre de la categoría"
                />
              </YStack>
            </YStack>

            <XStack gap="$3" justifyContent="flex-end">
              <Dialog.Close displayWhenAdapted asChild>
                <Button theme="alt1" aria-label="Close">
                  Cancelar
                </Button>
              </Dialog.Close>
              <Button
                onPress={handleSave}
                backgroundColor="$blue8"
                disabled={loading}
              >
                {loading ? "Guardando..." : "Guardar"}
              </Button>
            </XStack>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog>
    </YStack>
  );
}