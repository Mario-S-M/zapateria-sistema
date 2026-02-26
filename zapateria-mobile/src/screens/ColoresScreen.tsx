import React, { useState, useCallback } from "react";
import { FlatList, RefreshControl } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Card,
  H3,
  Button,
  Input,
  Separator,
  Sheet,
} from "tamagui";
import { useFocusEffect, useNavigation } from "@react-navigation/native";
import { colorService } from "../services/color.service";
import { Color } from "../types";
import { toast } from "sonner-native";
import { ColorCircle } from "../components/ColorCircle";
import { AdvancedColorPicker } from "../components/AdvancedColorPicker";
import { ThemeToggle } from "../components/ThemeToggle";

export default function ColoresScreen() {
  const [colores, setColores] = useState<Color[]>([]);
  const [allColores, setAllColores] = useState<Color[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingColor, setEditingColor] = useState<Color | null>(null);
  const itemsPerPage = 12;

  const navigation = useNavigation();

  useFocusEffect(
    useCallback(() => {
      loadColores();
    }, [])
  );

  const loadColores = async () => {
    try {
      const data = await colorService.getAll();
      setAllColores(data);
      filterColores(data, searchQuery);
    } catch (error) {
      console.error("Error loading colores:", error);
      toast.error("Error al cargar colores");
    }
  };

  const filterColores = (coloresData: Color[], query: string) => {
    let filtered = coloresData;

    if (query.trim()) {
      filtered = coloresData.filter((color) =>
        color.nombre.toLowerCase().includes(query.toLowerCase())
      );
    }

    setColores(filtered);
    setCurrentPage(1);
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    filterColores(allColores, query);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadColores();
    setRefreshing(false);
  };

  const handleCreateColor = () => {
    setEditingColor(null);
    setShowCreateModal(true);
  };

  const handleEditColor = (color: Color) => {
    setEditingColor(color);
    setShowCreateModal(true);
  };

  const handleDeleteColor = async (color: Color) => {
    try {
      await colorService.delete(color.id);
      await loadColores();
      toast.success("Color eliminado exitosamente");
    } catch (error) {
      console.error("Error deleting color:", error);
      toast.error("Error al eliminar color");
    }
  };

  // Paginación
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedColores = colores.slice(startIndex, endIndex);
  const totalPages = Math.ceil(colores.length / itemsPerPage);

  const handleNextPage = () => {
    if (currentPage < totalPages) {
      setCurrentPage(currentPage + 1);
    }
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  const renderItem = ({ item }: { item: Color }) => (
    <Card
      marginVertical="$1"
      marginHorizontal="$1"
      padding="$3"
      flex={1}
      maxWidth="45%"
      backgroundColor="$gray1"
      borderWidth={1}
      borderColor="$gray6"
      pressStyle={{ backgroundColor: "$gray2" }}
    >
      <YStack gap="$2" alignItems="center">
        <ColorCircle color={item} size={60} />

        <Text fontWeight="600" fontSize="$4" textAlign="center" color="$gray12">
          {item.nombre}
        </Text>

        {item.isCombo ? (
          <Text fontSize="$2" color="$gray10" textAlign="center" fontWeight="500">
            Combinación
          </Text>
        ) : (
          <Text fontSize="$2" color="$gray10" textAlign="center">
            {item.hexadecimal}
          </Text>
        )}

        <XStack gap="$2" marginTop="$2">
          <Button 
            size="$2" 
            backgroundColor="$gray8"
            color="$gray12"
            borderColor="$gray8"
            onPress={() => handleEditColor(item)}
            pressStyle={{ backgroundColor: "$gray9" }}
          >
            Editar
          </Button>
          <Button 
            size="$2" 
            backgroundColor="$red9"
            color="$gray1"
            borderColor="$red9"
            onPress={() => handleDeleteColor(item)}
            pressStyle={{ backgroundColor: "$red10" }}
          >
            Eliminar
          </Button>
        </XStack>
      </YStack>
    </Card>
  );

  const renderPagination = () => (
    <XStack
      justifyContent="space-between"
      alignItems="center"
      marginTop="$3"
      padding="$2"
    >
      <Button size="$3" disabled={currentPage === 1} onPress={handlePrevPage}>
        Anterior
      </Button>

      <YStack alignItems="center">
        <Text fontSize="$3">
          Página {currentPage} de {totalPages}
        </Text>
        <Text fontSize="$2" color="$gray10">
          {colores.length} colores encontrados
        </Text>
      </YStack>

      <Button
        size="$3"
        disabled={currentPage === totalPages}
        onPress={handleNextPage}
      >
        Siguiente
      </Button>
    </XStack>
  );

  return (
    <YStack flex={1} padding="$4">
      {/* Header con título y toggle de tema */}
      <XStack justifyContent="space-between" alignItems="center" marginBottom="$4">
        <H3 color="$gray12" fontWeight="600">Gestión de Colores</H3>
        <ThemeToggle showLabel={false} size="$2" />
      </XStack>

      {/* Barra de búsqueda y botones */}
      <XStack gap="$2" marginBottom="$3">
        <Input
          flex={1}
          placeholder="Buscar colores por nombre..."
          value={searchQuery}
          onChangeText={handleSearch}
          backgroundColor="$gray2"
          borderColor="$gray6"
          focusStyle={{ borderColor: "$gray9" }}
        />
        <Button 
          backgroundColor="$gray12" 
          color="$gray1"
          borderColor="$gray12"
          onPress={handleCreateColor}
          pressStyle={{ backgroundColor: "$gray11" }}
        >
          Nuevo Color
        </Button>
      </XStack>

      <Separator marginBottom="$3" />

      <FlatList
        data={paginatedColores}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        numColumns={2}
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
            <Text textAlign="center" marginBottom="$3">
              {searchQuery.trim()
                ? "No se encontraron colores con esa búsqueda"
                : "No hay colores registrados"}
            </Text>
            {!searchQuery.trim() && (
              <Button theme="blue" onPress={handleCreateColor}>
                Crear primer color
              </Button>
            )}
          </YStack>
        }
        ListFooterComponent={colores.length > 0 ? renderPagination : null}
      />

      {/* Modal para crear/editar color */}
      <Sheet 
        modal 
        open={showCreateModal} 
        onOpenChange={(open: boolean) => {
          if (!open) {
            setEditingColor(null); // Reset editing color when closing
          }
          setShowCreateModal(open);
        }}
        snapPointsMode="fit"
        dismissOnSnapToBottom
      >
        <Sheet.Frame padding={0} backgroundColor="$background">
          <Sheet.Handle />
          <AdvancedColorPicker
            initialColor={editingColor}
            onSave={async (colorData) => {
              try {
                if (editingColor) {
                  await colorService.update(editingColor.id, colorData);
                  toast.success("Color actualizado exitosamente");
                } else {
                  await colorService.create(colorData);
                  toast.success("Color creado exitosamente");
                }
                await loadColores();
                setEditingColor(null); // Reset editing color
                setShowCreateModal(false);
              } catch (error) {
                console.error("Error saving color:", error);
                toast.error("Error al guardar color");
              }
            }}
            onCancel={() => {
              setEditingColor(null); // Reset editing color
              setShowCreateModal(false);
            }}
          />
        </Sheet.Frame>
      </Sheet>
    </YStack>
  );
}


