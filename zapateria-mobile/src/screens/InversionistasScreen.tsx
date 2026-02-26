import React, { useState, useCallback } from "react";
import { FlatList, RefreshControl, Alert } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Card,
  H3,
  Button,
  Input,
  Separator,
  Switch,
  Sheet,
} from "tamagui";
import { useFocusEffect } from "@react-navigation/native";
import { inversionistaService } from "../services/inversionista.service";
import { Inversionista } from "../types";
import { toast } from "sonner-native";
import { InversionistaForm } from "../components/InversionistaForm";
import { ThemeToggle } from "../components/ThemeToggle";

export default function InversionistasScreen() {
  const [inversionistas, setInversionistas] = useState<Inversionista[]>([]);
  const [allInversionistas, setAllInversionistas] = useState<Inversionista[]>(
    []
  );
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [showOnlyActive, setShowOnlyActive] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [showFormModal, setShowFormModal] = useState(false);
  const [editingInversionista, setEditingInversionista] = useState<Inversionista | null>(null);
  const itemsPerPage = 10;

  useFocusEffect(
    useCallback(() => {
      loadInversionistas();
    }, [])
  );

  const loadInversionistas = async () => {
    try {
      const data = await inversionistaService.getAll();
      setAllInversionistas(data);
      filterInversionistas(data, searchQuery, showOnlyActive);
    } catch (error) {
      console.error("Error loading inversionistas:", error);
      toast.error("Error al cargar inversionistas");
    }
  };

  const filterInversionistas = (
    inversionistasData: Inversionista[],
    query: string,
    onlyActive: boolean
  ) => {
    let filtered = inversionistasData;

    if (onlyActive) {
      filtered = filtered.filter((inv) => inv.activo);
    }

    if (query.trim()) {
      filtered = filtered.filter(
        (inv) =>
          inv.nombre.toLowerCase().includes(query.toLowerCase()) ||
          inv.telefono?.includes(query) ||
          inv.email?.toLowerCase().includes(query.toLowerCase())
      );
    }

    setInversionistas(filtered);
    setCurrentPage(1);
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    filterInversionistas(allInversionistas, query, showOnlyActive);
  };

  const handleActiveFilter = (onlyActive: boolean) => {
    setShowOnlyActive(onlyActive);
    filterInversionistas(allInversionistas, searchQuery, onlyActive);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadInversionistas();
    setRefreshing(false);
  };

  const handleCreateInversionista = () => {
    setEditingInversionista(null);
    setShowFormModal(true);
  };

  const handleEditInversionista = (inversionista: Inversionista) => {
    setEditingInversionista(inversionista);
    setShowFormModal(true);
  };

  const handleDeleteInversionista = (inversionista: Inversionista) => {
    Alert.alert(
      "Confirmar eliminación",
      `¿Estás seguro de que deseas eliminar a "${inversionista.nombre}"?`,
      [
        {
          text: "Cancelar",
          style: "cancel",
        },
        {
          text: "Eliminar",
          style: "destructive",
          onPress: async () => {
            try {
              await inversionistaService.delete(inversionista.id);
              await loadInversionistas();
              toast.success("Inversionista eliminado exitosamente");
            } catch (error) {
              console.error("Error deleting inversionista:", error);
              toast.error("Error al eliminar inversionista");
            }
          },
        },
      ]
    );
  };

  const handleToggleActive = async (inversionista: Inversionista) => {
    try {
      await inversionistaService.update(inversionista.id, {
        activo: !inversionista.activo,
      });
      await loadInversionistas();
      toast.success(
        `Inversionista ${
          inversionista.activo ? "desactivado" : "activado"
        } exitosamente`
      );
    } catch (error) {
      console.error("Error toggling inversionista:", error);
      toast.error("Error al actualizar inversionista");
    }
  };

  // Paginación
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const paginatedInversionistas = inversionistas.slice(startIndex, endIndex);
  const totalPages = Math.ceil(inversionistas.length / itemsPerPage);

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

  const renderItem = ({ item }: { item: Inversionista }) => (
    <Card 
      marginVertical="$2" 
      padding="$3"
      backgroundColor="$gray1"
      borderWidth={1}
      borderColor="$gray6"
      pressStyle={{ backgroundColor: "$gray2" }}
      onPress={() => handleEditInversionista(item)}
    >
      <YStack gap="$3">
        {/* Header con nombre y estado */}
        <XStack justifyContent="space-between" alignItems="center">
          <Text fontWeight="600" fontSize="$5" flex={1} color="$gray12">
            {item.nombre}
          </Text>
          <XStack gap="$2" alignItems="center">
            <Text fontSize="$3" color={item.activo ? "$green9" : "$red9"} fontWeight="500">
              {item.activo ? "Activo" : "Inactivo"}
            </Text>
            <Switch
              size="$2"
              checked={item.activo}
              onCheckedChange={() => handleToggleActive(item)}
            />
          </XStack>
        </XStack>

        {/* Información adicional */}
        <YStack gap="$1">
          <XStack justifyContent="space-between">
            <Text color="$gray10" fontWeight="500">Fecha de registro:</Text>
            <Text fontSize="$3" color="$gray11">
              {new Date(item.createdAt).toLocaleDateString()}
            </Text>
          </XStack>
        </YStack>

        {/* Botones de acción */}
        <XStack gap="$2" justifyContent="flex-end">
          <Button 
            size="$2" 
            backgroundColor="$gray8"
            color="$gray12"
            borderColor="$gray8"
            onPress={() => handleEditInversionista(item)}
            pressStyle={{ backgroundColor: "$gray9" }}
          >
            Editar
          </Button>
          <Button 
            size="$2" 
            backgroundColor="$red9"
            color="$gray1"
            borderColor="$red9"
            onPress={() => handleDeleteInversionista(item)}
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
          {inversionistas.length} inversionistas encontrados
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
        <H3 color="$gray12" fontWeight="600">Gestión de Inversionistas</H3>
        <ThemeToggle showLabel={false} size="$2" />
      </XStack>

      {/* Controles de búsqueda y filtro */}
      <YStack gap="$3" marginBottom="$3">
        <Input
          placeholder="Buscar inversionista por nombre..."
          value={searchQuery}
          onChangeText={handleSearch}
          backgroundColor="$gray2"
          borderColor="$gray6"
          focusStyle={{ borderColor: "$gray9" }}
        />

        <XStack justifyContent="space-between" alignItems="center">
          <XStack gap="$2" alignItems="center">
            <Text fontWeight="500" color="$gray11">Solo activos</Text>
            <Switch
              size="$3"
              checked={showOnlyActive}
              onCheckedChange={handleActiveFilter}
            />
          </XStack>

          <Button 
            backgroundColor="$gray12" 
            color="$gray1"
            borderColor="$gray12"
            size="$3" 
            onPress={handleCreateInversionista}
            pressStyle={{ backgroundColor: "$gray11" }}
          >
            Nuevo Inversionista
          </Button>
        </XStack>
      </YStack>

      <Separator marginBottom="$3" />

      <FlatList
        data={paginatedInversionistas}
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
            <Text color="$gray10" fontSize="$4" textAlign="center">
              {searchQuery.trim() || showOnlyActive
                ? "No se encontraron inversionistas con los filtros aplicados"
                : "No hay inversionistas registrados en el sistema"}
            </Text>
            {!searchQuery.trim() && !showOnlyActive && (
              <Button 
                marginTop="$3" 
                backgroundColor="$gray12"
                color="$gray1"
                onPress={handleCreateInversionista}
              >
                Registrar primer inversionista
              </Button>
            )}
          </YStack>
        }
        ListFooterComponent={
          inversionistas.length > 0 ? renderPagination : null
        }
      />

      {/* Modal para crear/editar inversionista */}
      <Sheet 
        modal 
        open={showFormModal} 
        onOpenChange={(open: boolean) => {
          if (!open) {
            setEditingInversionista(null);
          }
          setShowFormModal(open);
        }}
        snapPointsMode="fit"
        dismissOnSnapToBottom
      >
        <Sheet.Frame padding={0} backgroundColor="$background">
          <Sheet.Handle />
          <InversionistaForm
            initialInversionista={editingInversionista}
            onSave={async (inversionistaData) => {
              try {
                if (editingInversionista) {
                  await inversionistaService.update(editingInversionista.id, inversionistaData);
                  toast.success("Inversionista actualizado exitosamente");
                } else {
                  await inversionistaService.create(inversionistaData);
                  toast.success("Inversionista creado exitosamente");
                }
                await loadInversionistas();
                setEditingInversionista(null);
                setShowFormModal(false);
              } catch (error) {
                console.error("Error saving inversionista:", error);
                toast.error("Error al guardar inversionista");
              }
            }}
            onCancel={() => {
              setEditingInversionista(null);
              setShowFormModal(false);
            }}
          />
        </Sheet.Frame>
      </Sheet>
    </YStack>
  );
}
