import React, { useState, useEffect } from "react";
import { ScrollView, Alert } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Button,
  Input,
  Card,
  Separator,
  Select,
  Adapt,
  Sheet,
} from "tamagui";
import {
  useNavigation,
  useRoute,
  RouteProp,
  NavigationProp,
} from "@react-navigation/native";
import { toast } from "sonner-native";
import { zapatoService } from "../services/zapato.service";
import { colorService } from "../services/color.service";
import { categoriaService } from "../services/categoria.service";
import { inversionistaService } from "../services/inversionista.service";
import { Zapato, Color, Categoria, Inversionista } from "../types";
import { formatPrice, parsePrice } from "../utils/priceUtils";
import {
  generateBarcode,
  validateBarcode,
  formatBarcode,
} from "../utils/barcodeUtils";
import { ZapatosStackParamList } from "../navigation/ZapatosStack";
import { ColorPicker } from "../components/ColorCircle";
import { ImagePickerComponent } from "../components/ImagePicker";
import { InversionistaForm } from "../components/InversionistaForm";
import { ColorPickerModal } from "../components/ColorPickerModal";
import { CategoryPickerModal } from "../components/CategoryPickerModal";

interface RouteParams {
  zapato?: Zapato;
}

type ZapatoFormRouteProp = RouteProp<ZapatosStackParamList, "ZapatoForm">;

export default function ZapatoFormScreen() {
  console.log("🚀 ZapatoFormScreen renderizado");
  
  const navigation = useNavigation<NavigationProp<ZapatosStackParamList>>();
  const route = useRoute<ZapatoFormRouteProp>();
  const params = route.params;
  const isEditing = !!params?.zapato;

  const [loading, setLoading] = useState(false);
  const [colores, setColores] = useState<Color[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [inversionistas, setInversionistas] = useState<Inversionista[]>([]);
  const [selectedColores, setSelectedColores] = useState<string[]>([]);

  // Form fields
  const [codigoBarras, setCodigoBarras] = useState("");
  const [nombre, setNombre] = useState("");
  const [modelo, setModelo] = useState("");
  const [foto, setFoto] = useState("");
  const [precioCompra, setPrecioCompra] = useState("");
  const [precioPublico, setPrecioPublico] = useState("");
  const [medidaInicio, setMedidaInicio] = useState("");
  const [medidaFin, setMedidaFin] = useState("");
  const [categoriaId, setCategoriaId] = useState("");
  const [inversionistaId, setInversionistaId] = useState("");
  const [showInversionistaModal, setShowInversionistaModal] = useState(false);
  const [creatingInversionista, setCreatingInversionista] = useState(false);
  const [showColorModal, setShowColorModal] = useState(false);
  const [showCategoryModal, setShowCategoryModal] = useState(false);

  useEffect(() => {
    console.log("🔄 useEffect ejecutándose - cargando datos");
    loadData();
    if (isEditing && params?.zapato) {
      const zapato = params.zapato;
      setCodigoBarras(zapato.codigoBarras);
      setNombre(zapato.nombre);
      setModelo(zapato.modelo);
      setFoto(zapato.foto || "");
      setPrecioCompra(zapato.precioCompra?.toString() || "");
      setPrecioPublico(zapato.precioPublico?.toString() || "");
      setMedidaInicio(zapato.medidaInicio?.toString() || "");
      setMedidaFin(zapato.medidaFin?.toString() || "");
      setSelectedColores(zapato.colores?.map((c) => c.colorId) || []);
      setCategoriaId(zapato.categoriaId || "");
      setInversionistaId(zapato.inversionistaId || "");
    } else {
      // Generar código automáticamente para nuevos zapatos
      setCodigoBarras(generateBarcode());
    }
  }, [isEditing, params]);

  const loadData = async () => {
    try {
      const [coloresData, categoriasData, inversionistasData] = await Promise.all([
        colorService.getAll(),
        categoriaService.getAll(),
        inversionistaService.getAll(),
      ]);
      console.log("Datos cargados:", {
        colores: coloresData.length,
        categorias: categoriasData.length,
        inversionistas: inversionistasData.length
      });
      setColores(coloresData);
      setCategorias(categoriasData);
      setInversionistas(inversionistasData);
    } catch (error) {
      console.error("Error al cargar datos:", error);
      toast.error("Error al cargar datos");
    }
  };

  const generateNewBarcode = () => {
    setCodigoBarras(generateBarcode());
  };

  const toggleColor = (colorId: string) => {
    if (selectedColores.includes(colorId)) {
      setSelectedColores(selectedColores.filter((id) => id !== colorId));
    } else {
      setSelectedColores([...selectedColores, colorId]);
    }
  };

  const validateForm = () => {
    if (!codigoBarras.trim()) {
      toast.error("El código de barras es requerido");
      return false;
    }
    if (!validateBarcode(codigoBarras)) {
      toast.error("El código de barras debe tener 12 dígitos");
      return false;
    }
    if (!nombre.trim()) {
      toast.error("El nombre es requerido");
      return false;
    }
    if (!modelo.trim()) {
      toast.error("El modelo es requerido");
      return false;
    }
    if (!foto.trim()) {
      toast.error("La foto es requerida");
      return false;
    }
    if (!precioCompra || parsePrice(precioCompra) <= 0) {
      toast.error("El precio de compra debe ser mayor a 0");
      return false;
    }
    if (!precioPublico || parsePrice(precioPublico) <= 0) {
      toast.error("El precio público debe ser mayor a 0");
      return false;
    }
    if (!medidaInicio || parseFloat(medidaInicio) <= 0) {
      toast.error("La medida inicial es requerida");
      return false;
    }
    if (!medidaFin || parseFloat(medidaFin) <= 0) {
      toast.error("La medida final es requerida");
      return false;
    }
    if (parseFloat(medidaInicio) >= parseFloat(medidaFin)) {
      toast.error("La medida final debe ser mayor a la inicial");
      return false;
    }
    if (selectedColores.length === 0) {
      toast.error("Selecciona al menos un color");
      return false;
    }
    if (!inversionistaId) {
      toast.error("El inversionista es requerido");
      return false;
    }
    return true;
  };

  const handleSave = async () => {
    if (!validateForm()) return;

    setLoading(true);
    try {
      const zapatoData = {
        codigoBarras: codigoBarras.trim(),
        nombre: nombre.trim(),
        modelo: modelo.trim(),
        foto: foto.trim(),
        precioCompra: parsePrice(precioCompra),
        precioPublico: parsePrice(precioPublico),
        medidaInicio: parseFloat(medidaInicio),
        medidaFin: parseFloat(medidaFin),
        colorIds: selectedColores,
        categoriaId: categoriaId || undefined,
        inversionistaId: inversionistaId,
      };

      if (isEditing) {
        await zapatoService.update(params.zapato!.id, zapatoData);
        toast.success("Zapato actualizado exitosamente");
      } else {
        await zapatoService.create(zapatoData);
        toast.success("Zapato creado exitosamente");
      }

      navigation.goBack();
    } catch (error: any) {
      console.error("Error al guardar zapato:", error);
      toast.error(error.response?.data?.message || "Error al guardar zapato");
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = () => {
    if (!isEditing) return;

    Alert.alert(
      "Eliminar Zapato",
      "¿Estás seguro de que quieres eliminar este zapato?",
      [
        { text: "Cancelar", style: "cancel" },
        { text: "Eliminar", style: "destructive", onPress: confirmDelete },
      ]
    );
  };

  const handleColorCreated = async () => {
    await loadData();
    toast.success("Color creado");
  };

  const handleCategoryCreated = async () => {
    await loadData();
    toast.success("Categoría creada");
  };

  const handleCreateInversionista = async (
    data: { nombre: string; activo?: boolean }
  ) => {
    setCreatingInversionista(true);
    try {
      const nuevo = await inversionistaService.create({
        nombre: data.nombre,
        activo: data.activo ?? true,
      });
      await loadData();
      setInversionistaId(nuevo.id);
      toast.success("Inversionista creado exitosamente");
      setShowInversionistaModal(false);
    } catch (error: any) {
      console.error("Error al crear inversionista:", error);
      toast.error(error.response?.data?.message || "Error al crear inversionista");
    } finally {
      setCreatingInversionista(false);
    }
  };

  const confirmDelete = async () => {
    if (!params?.zapato) return;

    setLoading(true);
    try {
      await zapatoService.delete(params.zapato.id);
      toast.success("Zapato eliminado exitosamente");
      navigation.goBack();
    } catch (error) {
      console.error("Error al eliminar zapato:", error);
      toast.error("Error al eliminar zapato");
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={{ flex: 1 }}>
      <YStack flex={1} padding="$4" gap="$4">
        
        <Text fontSize="$6" fontWeight="bold" textAlign="center" marginBottom="$4">
          {isEditing ? "Editar Zapato" : "Nuevo Zapato"}
        </Text>

        <Card padding="$4">
          <YStack gap="$3">
            <YStack gap="$2">
              <XStack justifyContent="space-between" alignItems="center">
                <Text fontWeight="bold">Código de Barras *</Text>
                <Button size="$2" theme="blue" onPress={generateNewBarcode}>
                  Generar
                </Button>
              </XStack>
              <Input
                value={codigoBarras}
                onChangeText={setCodigoBarras}
                placeholder="Ej: 123456789012"
                keyboardType="numeric"
              />
              {codigoBarras && (
                <Text fontSize="$2" color="$gray10">
                  Formato: {formatBarcode(codigoBarras)}
                </Text>
              )}
            </YStack>

            <YStack gap="$2">
              <Text fontWeight="bold">Nombre *</Text>
              <Input
                value={nombre}
                onChangeText={setNombre}
                placeholder="Ej: Zapato Casual"
              />
            </YStack>

            <YStack gap="$2">
              <Text fontWeight="bold">Modelo *</Text>
              <Input
                value={modelo}
                onChangeText={setModelo}
                placeholder="Ej: CASUAL-001"
              />
            </YStack>

            <YStack gap="$2">
              <Text fontWeight="bold">Foto del Zapato *</Text>
              <ImagePickerComponent
                onImageSelected={setFoto}
                disabled={loading}
              />
              {foto ? (
                <Text fontSize="$2" color="$green10">
                  ✓ Imagen seleccionada
                </Text>
              ) : null}
            </YStack>

            <XStack gap="$3">
              <YStack flex={1} gap="$2">
                <Text fontWeight="bold">Precio Compra *</Text>
                <Input
                  value={precioCompra}
                  onChangeText={setPrecioCompra}
                  placeholder="200.00"
                  keyboardType="numeric"
                />
              </YStack>

              <YStack flex={1} gap="$2">
                <Text fontWeight="bold">Precio Público *</Text>
                <Input
                  value={precioPublico}
                  onChangeText={setPrecioPublico}
                  placeholder="350.00"
                  keyboardType="numeric"
                />
              </YStack>
            </XStack>

            <XStack gap="$3">
              <YStack flex={1} gap="$2">
                <Text fontWeight="bold">Medida Inicio *</Text>
                <Input
                  value={medidaInicio}
                  onChangeText={setMedidaInicio}
                  placeholder="23.0"
                  keyboardType="numeric"
                />
              </YStack>

              <YStack flex={1} gap="$2">
                <Text fontWeight="bold">Medida Fin *</Text>
                <Input
                  value={medidaFin}
                  onChangeText={setMedidaFin}
                  placeholder="28.0"
                  keyboardType="numeric"
                />
              </YStack>
            </XStack>

            <Separator marginVertical="$2" />

            <YStack gap="$2">
              <Text fontWeight="bold">Categoría</Text>
              <Button
                size="$2"
                theme="green"
                alignSelf="flex-start"
                onPress={() => setShowCategoryModal(true)}
              >
                Crear categoría
              </Button>
              <Select value={categoriaId} onValueChange={setCategoriaId}>
                <Select.Trigger>
                  <Select.Value placeholder="Seleccionar categoría" />
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
                    <Select.Item value="" index={0}>
                      <Select.ItemText>Sin categoría</Select.ItemText>
                    </Select.Item>
                    {categorias.map((categoria, idx) => (
                      <Select.Item key={categoria.id} value={categoria.id} index={idx + 1}>
                        <Select.ItemText>{categoria.nombre}</Select.ItemText>
                      </Select.Item>
                    ))}
                  </Select.Viewport>
                  <Select.ScrollDownButton />
                </Select.Content>
              </Select>
            </YStack>
            <Separator marginVertical="$2" />

            <YStack gap="$2">
              <XStack justifyContent="space-between" alignItems="center">
                <Text fontWeight="bold">Inversionista *</Text>
                <Button
                  size="$2"
                  theme="green"
                  onPress={() => setShowInversionistaModal(true)}
                >
                  Crear inversionista
                </Button>
              </XStack>
              <Select
                value={inversionistaId}
                onValueChange={setInversionistaId}
              >
                <Select.Trigger>
                  <Select.Value placeholder="Seleccionar inversionista" />
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
                    {inversionistas.map((inv, idx) => (
                      <Select.Item key={inv.id} value={inv.id} index={idx}>
                        <Select.ItemText>{inv.nombre}</Select.ItemText>
                      </Select.Item>
                    ))}
                  </Select.Viewport>
                  <Select.ScrollDownButton />
                </Select.Content>
              </Select>
            </YStack>
          </YStack>
        </Card>

        <Card padding="$4">
          <YStack gap="$3">
            <XStack justifyContent="space-between" alignItems="center">
              <Text fontWeight="bold" fontSize="$5">
                Colores Disponibles *
              </Text>
              <Button
                size="$2"
                theme="purple"
                onPress={() => setShowColorModal(true)}
              >
                Crear color
              </Button>
            </XStack>
            <Text color="$gray10">
              Selecciona los colores disponibles para este zapato
            </Text>

            <ColorPicker
              colors={colores}
              selectedColorIds={selectedColores}
              onColorSelect={toggleColor}
            />

            {selectedColores.length > 0 && (
              <Text color="$green10" fontSize="$3" textAlign="center">
                {selectedColores.length} color(es) seleccionado(s)
              </Text>
            )}
          </YStack>
        </Card>

        <XStack gap="$3" marginTop="$4">
          <Button
            flex={1}
            variant="outlined"
            onPress={() => navigation.goBack()}
            disabled={loading}
          >
            Cancelar
          </Button>

          {isEditing && (
            <Button theme="red" onPress={handleDelete} disabled={loading}>
              Eliminar
            </Button>
          )}

          <Button flex={1} theme="blue" onPress={handleSave} disabled={loading}>
            {loading ? "Guardando..." : isEditing ? "Actualizar" : "Crear"}
          </Button>
        </XStack>
      </YStack>

      <ColorPickerModal
        visible={showColorModal}
        onClose={() => setShowColorModal(false)}
        onColorCreated={handleColorCreated}
      />

      <CategoryPickerModal
        visible={showCategoryModal}
        onClose={() => setShowCategoryModal(false)}
        onCategoryCreated={handleCategoryCreated}
      />

      <Sheet
        modal
        open={showInversionistaModal}
        onOpenChange={setShowInversionistaModal}
        snapPointsMode="fit"
      >
        <Sheet.Overlay />
        <Sheet.Frame padding="$4">
          <InversionistaForm
            initialInversionista={null}
            onSave={handleCreateInversionista}
            onCancel={() => setShowInversionistaModal(false)}
          />
          {creatingInversionista && (
            <Text textAlign="center" marginTop="$2">Creando inversionista...</Text>
          )}
        </Sheet.Frame>
      </Sheet>
    </ScrollView>
  );
}
