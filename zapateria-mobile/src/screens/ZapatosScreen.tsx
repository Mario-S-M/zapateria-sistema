import React, { useEffect, useState, useCallback } from "react";
import { FlatList, RefreshControl, Alert, Image } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import {
  YStack,
  XStack,
  Text,
  Card,
  Button,
  Input,
  Separator,
  Sheet,
  Spinner,
} from "tamagui";
import {
  useNavigation,
  useFocusEffect,
  NavigationProp,
} from "@react-navigation/native";
import { zapatoService, CreateZapatoDto } from "../services/zapato.service";
import { Zapato, TipoPrecio } from "../types";
import { toast } from "sonner-native";
import { useCartStore } from "../store/cart";
import { parsePrice } from "../utils/priceUtils";
import { ZapatosStackParamList } from "../navigation/ZapatosStack";
import { ThemeToggle } from "../components/ThemeToggle";
import { ZapatoForm } from "../components/ZapatoForm";
import { BarcodeDisplay } from "../components/BarcodeDisplay";

export default function ZapatosScreen() {
  const [zapatos, setZapatos] = useState<Zapato[]>([]);
  const [allZapatos, setAllZapatos] = useState<Zapato[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [showFormModal, setShowFormModal] = useState(false);
  const [editingZapato, setEditingZapato] = useState<Zapato | null>(null);
  const itemsPerPage = 10;

  const { addItem, tipoPrecio } = useCartStore();
  const navigation = useNavigation<NavigationProp<ZapatosStackParamList>>();

  const loadZapatos = async () => {
    try {
      setLoading(true);
      const data = await zapatoService.getAll();
      setAllZapatos(data || []);
      filterZapatos(data || [], searchQuery);
    } catch (error) {
      console.error("Error loading zapatos:", error);
      toast.error("Error al cargar zapatos");
      setAllZapatos([]);
      setZapatos([]);
    } finally {
      setLoading(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      loadZapatos();
    }, [])
  );

  const filterZapatos = (zapatosData: Zapato[], query: string) => {
    // Validar que zapatosData es un array válido
    if (!Array.isArray(zapatosData)) {
      console.warn('filterZapatos: zapatosData no es un array válido', zapatosData);
      setZapatos([]);
      return;
    }

    let filtered = zapatosData;

    if (query && query.trim()) {
      filtered = zapatosData.filter((zapato) => {
        // Validar que cada zapato es un objeto válido
        if (!zapato || typeof zapato !== 'object') return false;
        
        const nombre = typeof zapato.nombre === 'string' ? zapato.nombre.toLowerCase() : '';
        const modelo = typeof zapato.modelo === 'string' ? zapato.modelo.toLowerCase() : '';
        const codigo = typeof zapato.codigoBarras === 'string' ? zapato.codigoBarras : '';
        const queryLower = query.toLowerCase();

        return nombre.includes(queryLower) || 
               modelo.includes(queryLower) || 
               codigo.includes(query);
      });
    }

    setZapatos(filtered || []);
    setCurrentPage(1);
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    filterZapatos(allZapatos, query);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadZapatos();
    setRefreshing(false);
  };

  const handleCreateZapato = () => {
    setEditingZapato(null);
    setShowFormModal(true);
  };

  const handleEditZapato = (zapato: Zapato) => {
    setEditingZapato(zapato);
    setShowFormModal(true);
  };

  const handleDeleteZapato = (zapato: Zapato) => {
    Alert.alert(
      "Confirmar Eliminación",
      `¿Está seguro de que desea eliminar "${zapato.nombre}"?`,
      [
        { text: "Cancelar", style: "cancel" },
        { 
          text: "Eliminar", 
          style: "destructive",
          onPress: async () => {
            try {
              await zapatoService.delete(zapato.id);
              await loadZapatos();
              toast.success("Zapato eliminado exitosamente");
            } catch (error: any) {
              console.error("Error deleting zapato:", error);
              const errorMessage = error.response?.data?.message || "Error al eliminar zapato";
              toast.error(errorMessage);
            }
          }
        }
      ]
    );
  };

  const handleSaveZapato = async (zapatoData: CreateZapatoDto) => {
    try {
      if (editingZapato) {
        await zapatoService.update(editingZapato.id, zapatoData);
        toast.success("Zapato actualizado exitosamente");
      } else {
        await zapatoService.create(zapatoData);
        toast.success("Zapato creado exitosamente");
      }
      
      setShowFormModal(false);
      setEditingZapato(null);
      await loadZapatos();
    } catch (error) {
      console.error("Error saving zapato:", error);
      toast.error(editingZapato ? "Error al actualizar zapato" : "Error al crear zapato");
    }
  };

  const handleCloseForm = () => {
    setShowFormModal(false);
    setEditingZapato(null);
  };

  const handleAddToCart = (zapato: Zapato) => {
    const precioPublico = parsePrice(zapato.precioPublico);
    const precioCompra = parsePrice(zapato.precioCompra);

    let precio = precioPublico;
    if (tipoPrecio === TipoPrecio.MAYORISTA && precioCompra > 0) {
      precio = precioCompra * 1.3;
    } else if (tipoPrecio === TipoPrecio.INVERSIONISTA && precioCompra > 0) {
      precio = precioCompra * 1.2;
    }

    addItem(zapato, 1, precio);
    toast.success(`${zapato.nombre} agregado al carrito`);
  };



  // Paginación
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const safeZapatos = Array.isArray(zapatos) ? zapatos : [];
  const paginatedZapatos = safeZapatos.slice(startIndex, endIndex);
  const totalPages = Math.ceil(safeZapatos.length / itemsPerPage);

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

  const renderItem = ({ item }: { item: Zapato }) => {
    if (!item || typeof item !== 'object') {
      return (
        <YStack
          marginVertical="$2"
          padding="$3"
          backgroundColor="$gray1"
          borderWidth={1}
          borderColor="$gray6"
          borderRadius="$4"
        >
          <Text color="$red10">Error: Zapato no disponible</Text>
        </YStack>
      );
    }

    return (
      <YStack
        marginVertical="$2"
        padding="$3"
        backgroundColor="$gray1"
        borderWidth={1}
        borderColor="$gray6"
        borderRadius="$4"
      >
        {/* Foto y información básica */}
        <XStack space="$3" alignItems="center">
          {item.foto ? (
            <Image
              source={{ uri: item.foto }}
              style={{ width: 60, height: 60, borderRadius: 8 }}
              resizeMode="cover"
            />
          ) : (
            <YStack
              width={60}
              height={60}
              backgroundColor="$gray4"
              borderRadius="$2"
              justifyContent="center"
              alignItems="center"
            >
              <Text fontSize="$3" color="$gray10">Sin foto</Text>
            </YStack>
          )}

          <YStack flex={1} space="$1">
            <Text fontSize="$4" fontWeight="bold" numberOfLines={1}>
              {String(item.nombre || 'Sin nombre')}
            </Text>
            <Text fontSize="$3" color="$gray10" numberOfLines={1}>
              Modelo: {String(item.modelo || 'Sin modelo')}
            </Text>
          </YStack>
        </XStack>

        {/* Código de barras funcional */}
        {item.codigoBarras && (
          <YStack marginTop="$3" alignItems="center">
            <BarcodeDisplay
              code={String(item.codigoBarras)}
              width={300}
              height={60}
              color="#000000"
              showLabel={false}
            />
            <Text fontSize="$2" color="$gray8" marginTop="$1">
              {String(item.codigoBarras)}
            </Text>
          </YStack>
        )}

        {/* Categoría e Inversionista */}
        <XStack space="$2" marginTop="$2">
          {item.categoria && (
            <YStack flex={1}>
              <Text fontSize="$2" color="$gray9" fontWeight="600">
                Categoría
              </Text>
              <Text fontSize="$3" color="$gray12">
                {String(item.categoria.nombre || 'Sin categoría')}
              </Text>
            </YStack>
          )}

          {item.inversionista && (
            <YStack flex={1}>
              <Text fontSize="$2" color="$gray9" fontWeight="600">
                Inversionista
              </Text>
              <Text fontSize="$3" color="$gray12">
                {String(item.inversionista.nombre || 'Sin inversionista')}
              </Text>
            </YStack>
          )}
        </XStack>

        {/* Precios */}
        <XStack space="$2" marginTop="$2">
          <YStack flex={1}>
            <Text fontSize="$2" color="$gray9" fontWeight="600">
              Precio Público
            </Text>
            <Text fontSize="$3" color="$green10" fontWeight="600">
              ${String(item.precioPublico || 0)}
            </Text>
          </YStack>

          <YStack flex={1}>
            <Text fontSize="$2" color="$gray9" fontWeight="600">
              Precio Compra
            </Text>
            <Text fontSize="$3" color="$blue10" fontWeight="600">
              ${String(item.precioCompra || 0)}
            </Text>
          </YStack>
        </XStack>

        {/* Medidas */}
        <XStack space="$2" marginTop="$2">
          <YStack flex={1}>
            <Text fontSize="$2" color="$gray9" fontWeight="600">
              Medidas
            </Text>
            <Text fontSize="$3" color="$gray12">
              {String(item.medidaInicio || 0)} - {String(item.medidaFin || 0)}
            </Text>
          </YStack>

          <YStack flex={1}>
            <Text fontSize="$2" color="$gray9" fontWeight="600">
              Colores
            </Text>
            <Text fontSize="$3" color="$gray12">
              {String(item.colores?.length || 0)} colores
            </Text>
          </YStack>
        </XStack>

        {/* Botones de acciones */}
        <XStack space="$2" marginTop="$3">
          <Button
            size="$4"
            backgroundColor="$gray8"
            borderColor="$gray8"
            onPress={() => handleEditZapato(item)}
            flex={1}
            icon={<Ionicons name="pencil" size={20} color="white" />}
            pressStyle={{ backgroundColor: "$gray10" }}
          />

          <Button
            size="$4"
            backgroundColor="$gray8"
            borderColor="$gray8"
            onPress={() => handleAddToCart(item)}
            flex={1}
            icon={<Ionicons name="cart" size={20} color="white" />}
            pressStyle={{ backgroundColor: "$gray10" }}
          />

          <Button
            size="$4"
            backgroundColor="$gray8"
            borderColor="$gray8"
            onPress={() => handleDeleteZapato(item)}
            flex={1}
            icon={<Ionicons name="trash" size={20} color="white" />}
            pressStyle={{ backgroundColor: "$gray10" }}
          />
        </XStack>
      </YStack>
    );
  };

  const renderPagination = () => (
    <XStack
      justifyContent="space-between"
      alignItems="center"
      marginTop="$3"
      padding="$2"
    >
      <Button size="$3" disabled={currentPage === 1} onPress={handlePrevPage}>
        <Text>Anterior</Text>
      </Button>

      <YStack alignItems="center">
        <Text fontSize="$3">
          Página {String(currentPage)} de {String(totalPages)}
        </Text>
        <Text fontSize="$2" color="$gray10">
          {String(zapatos.length)} zapatos encontrados
        </Text>
      </YStack>

      <Button
        size="$3"
        disabled={currentPage === totalPages}
        onPress={handleNextPage}
      >
        <Text>Siguiente</Text>
      </Button>
    </XStack>
  );

  // Mostrar pantalla de loading mientras cargan los datos
  if (loading) {
    return (
      <YStack flex={1} justifyContent="center" alignItems="center" padding="$4">
        <Spinner size="large" color="$blue10" />
        <Text marginTop="$3" fontSize="$4" color="$gray10">
          Cargando zapatos...
        </Text>
      </YStack>
    );
  }

  return (
    <YStack flex={1} padding="$4">
      {/* Header con título y toggle de tema */}
      <XStack justifyContent="space-between" alignItems="center" marginBottom="$4">
        <Text fontSize="$6" fontWeight="600" color="$gray12">Gestión de Zapatos</Text>
        <ThemeToggle showLabel={false} size="$2" />
      </XStack>

      {/* Barra de búsqueda y botón crear */}
      <XStack gap="$2" marginBottom="$3">
        <Input
          flex={1}
          placeholder="Buscar por nombre, modelo o código..."
          value={searchQuery}
          onChangeText={handleSearch}
          backgroundColor="$gray2"
          borderColor="$gray6"
          focusStyle={{ borderColor: "$gray9" }}
        />
        <Button
          backgroundColor="$gray12"
          borderColor="$gray12"
          onPress={handleCreateZapato}
          pressStyle={{ backgroundColor: "$gray11" }}
        >
          <Text color="$gray1">Nuevo Zapato</Text>
        </Button>
      </XStack>

      <Separator marginBottom="$3" />

      <FlatList
        data={Array.isArray(paginatedZapatos) ? paginatedZapatos : []}
        renderItem={renderItem}
        keyExtractor={(item, index) => (item && item.id) ? item.id : `item-${index}`}
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
              {(searchQuery && searchQuery.trim())
                ? "No se encontraron zapatos con los filtros aplicados"
                : "No hay zapatos registrados en el sistema"}
            </Text>
            {!(searchQuery && searchQuery.trim()) && (
              <Button
                marginTop="$3"
                backgroundColor="$gray12"
                onPress={handleCreateZapato}
              >
                <Text color="$gray1">Registrar primer zapato</Text>
              </Button>
            )}
          </YStack>
        }
        ListFooterComponent={zapatos.length > 0 ? renderPagination : null}
      />

      {/* Modal del formulario - Solo renderizar cuando esté abierto */}
      {showFormModal && (
        <Sheet
          modal
          open={showFormModal}
          onOpenChange={setShowFormModal}
          snapPoints={[90]}
          dismissOnSnapToBottom
        >
          <Sheet.Overlay />
          <Sheet.Handle />
          <Sheet.Frame>
            <ZapatoForm
              initialZapato={editingZapato}
              onSave={handleSaveZapato}
              onCancel={handleCloseForm}
            />
          </Sheet.Frame>
        </Sheet>
      )}
    </YStack>
  );
}
