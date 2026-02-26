import React, { useState, useEffect } from "react";
import { ScrollView, Dimensions, Alert, Image } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Button,
  Input,
  Card,
  H5,
  Separator,
  Sheet,
} from "tamagui";
import { Zapato, Color, Categoria, Inversionista } from "../types";
import { CreateZapatoDto } from "../services/zapato.service";
import { colorService } from "../services/color.service";
import { categoriaService } from "../services/categoria.service";
import { inversionistaService } from "../services/inversionista.service";
import { ColorCircle } from "./ColorCircle";
import { ImagePickerComponent } from "./ImagePicker";
import { ZapatoImage } from "./ZapatoImage";
import { BarcodeScanner } from "./BarcodeScanner";
import { ColorPickerModal } from "./ColorPickerModal";
import { CategoryPickerModal } from "./CategoryPickerModal";
import { InversionistaForm } from "./InversionistaForm";
import { MaterialIcons } from "@expo/vector-icons";

const { height: screenHeight } = Dimensions.get("window");

interface ZapatoFormProps {
  initialZapato?: Zapato | null;
  onSave: (zapatoData: CreateZapatoDto) => void;
  onCancel: () => void;
}

export const ZapatoForm: React.FC<ZapatoFormProps> = ({
  initialZapato,
  onSave,
  onCancel,
}) => {
  // Estados del formulario
  const [codigoBarras, setCodigoBarras] = useState(initialZapato?.codigoBarras || "");
  const [nombre, setNombre] = useState(initialZapato?.nombre || "");
  const [modelo, setModelo] = useState(initialZapato?.modelo || "");
  const [foto, setFoto] = useState(initialZapato?.foto || "");
  const [precioCompra, setPrecioCompra] = useState(
    initialZapato?.precioCompra ? initialZapato.precioCompra.toString() : ""
  );
  const [precioPublico, setPrecioPublico] = useState(
    initialZapato?.precioPublico ? initialZapato.precioPublico.toString() : ""
  );
  const [medidaInicio, setMedidaInicio] = useState(
    initialZapato?.medidaInicio ? initialZapato.medidaInicio.toString() : ""
  );
  const [medidaFin, setMedidaFin] = useState(
    initialZapato?.medidaFin ? initialZapato.medidaFin.toString() : ""
  );

  // Estados para colores
  const [availableColors, setAvailableColors] = useState<Color[]>([]);
  const [selectedColorIds, setSelectedColorIds] = useState<string[]>([]);

  // Estados para categorías e inversionistas
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [inversionistas, setInversionistas] = useState<Inversionista[]>([]);
  const [categoriaId, setCategoriaId] = useState(initialZapato?.categoriaId || "");
  const [inversionistaId, setInversionistaId] = useState(initialZapato?.inversionistaId || "");
  const [showInversionistaModal, setShowInversionistaModal] = useState(false);
  const [creatingInversionista, setCreatingInversionista] = useState(false);

  // Estados de validación
  const [errors, setErrors] = useState<{[key: string]: string}>({});

  // Estado para el scanner de códigos de barras
  const [showBarcodeScanner, setShowBarcodeScanner] = useState(false);

  // Estado para el color picker modal
  const [showColorPickerModal, setShowColorPickerModal] = useState(false);

  // Estado para el category picker modal
  const [showCategoryPickerModal, setShowCategoryPickerModal] = useState(false);

  // Cargar datos disponibles y establecer valores seleccionados
  useEffect(() => {
    loadData();
    if (initialZapato && initialZapato.colores) {
      setSelectedColorIds(initialZapato.colores.map(zc => zc.colorId));
    }
  }, [initialZapato]);

  // Limpiar campos cuando cambie initialZapato
  useEffect(() => {
    if (initialZapato) {
      setCodigoBarras(initialZapato.codigoBarras || "");
      setNombre(initialZapato.nombre || "");
      setModelo(initialZapato.modelo || "");
      setFoto(initialZapato.foto || "");
      setPrecioCompra(initialZapato.precioCompra ? initialZapato.precioCompra.toString() : "");
      setPrecioPublico(initialZapato.precioPublico ? initialZapato.precioPublico.toString() : "");
      setMedidaInicio(initialZapato.medidaInicio ? initialZapato.medidaInicio.toString() : "");
      setMedidaFin(initialZapato.medidaFin ? initialZapato.medidaFin.toString() : "");
      setSelectedColorIds(initialZapato.colores?.map(zc => zc.colorId) || []);
    } else {
      // Reset para nuevo zapato
      setCodigoBarras("");
      setNombre("");
      setModelo("");
      setFoto("");
      setPrecioCompra("");
      setPrecioPublico("");
      setMedidaInicio("");
      setMedidaFin("");
      setSelectedColorIds([]);
    }
    setErrors({});
  }, [initialZapato]);

  const loadData = async () => {
    try {
      const [colors, categoriasData, inversionistasData] = await Promise.all([
        colorService.getAll(),
        categoriaService.getAll(),
        inversionistaService.getAll(),
      ]);
      
      setAvailableColors(colors);
      setCategorias(categoriasData);
      setInversionistas(inversionistasData);
      
      console.log("🔄 ZapatoForm - Datos cargados:", {
        colores: colors.length,
        categorias: categoriasData.length,
        inversionistas: inversionistasData.length
      });
    } catch (error) {
      console.error("Error loading data:", error);
    }
  };

  const validateForm = (): boolean => {
    const newErrors: {[key: string]: string} = {};

    if (!codigoBarras.trim()) {
      newErrors.codigoBarras = "El código de barras es requerido";
    }
    if (!nombre.trim()) {
      newErrors.nombre = "El nombre es requerido";
    }
    if (!modelo.trim()) {
      newErrors.modelo = "El modelo es requerido";
    }
    if (!foto.trim()) {
      newErrors.foto = "La foto es requerida";
    }
    
    const precioCompraNum = parseFloat(precioCompra);
    if (!precioCompra || isNaN(precioCompraNum) || precioCompraNum <= 0) {
      newErrors.precioCompra = "Precio de compra debe ser un número positivo";
    }
    
    const precioPublicoNum = parseFloat(precioPublico);
    if (!precioPublico || isNaN(precioPublicoNum) || precioPublicoNum <= 0) {
      newErrors.precioPublico = "Precio público debe ser un número positivo";
    }

    const medidaInicioNum = parseFloat(medidaInicio);
    if (!medidaInicio || isNaN(medidaInicioNum) || medidaInicioNum <= 0) {
      newErrors.medidaInicio = "Medida inicial debe ser un número positivo";
    }

    const medidaFinNum = parseFloat(medidaFin);
    if (!medidaFin || isNaN(medidaFinNum) || medidaFinNum <= 0) {
      newErrors.medidaFin = "Medida final debe ser un número positivo";
    }

    if (medidaInicioNum >= medidaFinNum) {
      newErrors.medidaRango = "La medida inicial debe ser menor que la final";
    }

    if (selectedColorIds.length === 0) {
      newErrors.colores = "Debe seleccionar al menos un color";
    }

    if (!inversionistaId.trim()) {
      newErrors.inversionista = "El inversionista es requerido";
    }

    if (precioCompraNum >= precioPublicoNum) {
      newErrors.precios = "El precio de compra debe ser menor al público";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = () => {
    if (!validateForm()) {
      return;
    }

    const zapatoData: CreateZapatoDto = {
      codigoBarras: codigoBarras.trim(),
      nombre: nombre.trim(),
      modelo: modelo.trim(),
      foto: foto.trim(),
      precioCompra: parseFloat(precioCompra),
      precioPublico: parseFloat(precioPublico),
      medidaInicio: parseFloat(medidaInicio),
      medidaFin: parseFloat(medidaFin),
      colorIds: selectedColorIds,
      categoriaId: categoriaId || undefined,
      inversionistaId: inversionistaId,
    };

    onSave(zapatoData);
  };

  const toggleColorSelection = (colorId: string) => {
    setSelectedColorIds(prev => 
      prev.includes(colorId)
        ? prev.filter(id => id !== colorId)
        : [...prev, colorId]
    );
  };

  const handleBarcodeScanned = (barcode: string) => {
    setCodigoBarras(barcode);
    setShowBarcodeScanner(false);
  };

  const handleColorCreated = async () => {
    // Recargar los colores disponibles después de crear uno nuevo
    const colors = await colorService.getAll();
    setAvailableColors(colors);
  };

  const handleCategoryCreated = async () => {
    // Recargar las categorías disponibles después de crear una nueva
    const cats = await categoriaService.getAll();
    setCategorias(cats);
  };

  const handleInversionistaCreated = async (data: { nombre: string; activo?: boolean }) => {
    setCreatingInversionista(true);
    try {
      const nuevo = await inversionistaService.create({
        nombre: data.nombre,
        activo: data.activo ?? true,
      });
      await loadData();
      setInversionistaId(nuevo.id);
      setShowInversionistaModal(false);
    } catch (error) {
      console.error("Error creando inversionista:", error);
    } finally {
      setCreatingInversionista(false);
    }
  };

  const selectedColors = availableColors.filter(color => 
    selectedColorIds.includes(color.id)
  );

  return (
    <YStack flex={1} height={screenHeight * 0.9}>
      <YStack padding="$4" paddingBottom="$2" backgroundColor="$gray2">
        <XStack alignItems="center" justifyContent="center" gap="$2">
          <Text fontSize="$6" color="$gray11">
            {initialZapato ? "✏️" : "👟"}
          </Text>
          <H5 textAlign="center" color="$gray12" fontWeight="700">
            {initialZapato ? "Editar Zapato" : "Nuevo Zapato"}
          </H5>
        </XStack>
      </YStack>

      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{
          paddingHorizontal: 16,
          paddingBottom: 20,
          minHeight: 600,
        }}
        showsVerticalScrollIndicator={true}
        bounces={true}
      >
        <YStack gap="$4" paddingVertical="$3">
          {/* Información básica */}
          <Card 
            padding="$4" 
            backgroundColor="$gray1"
            borderWidth={1}
            borderColor="$gray6"
          >
            <YStack gap="$4">
              <Text fontSize="$4" fontWeight="600" color="$gray12">
                Información Básica
              </Text>

              <YStack gap="$2">
                <Text fontWeight="500" color="$gray11">Código de Barras *</Text>
                <XStack gap="$2" alignItems="center">
                  <YStack flex={1}>
                    <Input
                      value={codigoBarras}
                      onChangeText={setCodigoBarras}
                      placeholder="Ingrese el código de barras"
                      backgroundColor="$gray2"
                      borderColor={errors.codigoBarras ? "$red9" : "$gray6"}
                      focusStyle={{ borderColor: errors.codigoBarras ? "$red9" : "$gray9" }}
                    />
                  </YStack>
                  <Button
                    size="$4"
                    circular
                    backgroundColor="transparent"
                    onPress={() => setShowBarcodeScanner(true)}
                    pressStyle={{ scale: 0.95, opacity: 0.7 }}
                  >
                    <MaterialIcons name="qr-code-scanner" size={24} color="black" />
                  </Button>
                </XStack>
                {errors.codigoBarras && (
                  <Text fontSize="$2" color="$red9">{errors.codigoBarras}</Text>
                )}
              </YStack>

              <YStack gap="$2">
                <Text fontWeight="500" color="$gray11">Nombre del Zapato *</Text>
                <Input
                  value={nombre}
                  onChangeText={setNombre}
                  placeholder="Ej: Zapato deportivo Nike"
                  backgroundColor="$gray2"
                  borderColor={errors.nombre ? "$red9" : "$gray6"}
                  focusStyle={{ borderColor: errors.nombre ? "$red9" : "$gray9" }}
                />
                {errors.nombre && (
                  <Text fontSize="$2" color="$red9">{errors.nombre}</Text>
                )}
              </YStack>

              <YStack gap="$2">
                <Text fontWeight="500" color="$gray11">Modelo *</Text>
                <Input
                  value={modelo}
                  onChangeText={setModelo}
                  placeholder="Ej: Air Max 270"
                  backgroundColor="$gray2"
                  borderColor={errors.modelo ? "$red9" : "$gray6"}
                  focusStyle={{ borderColor: errors.modelo ? "$red9" : "$gray9" }}
                />
                {errors.modelo && (
                  <Text fontSize="$2" color="$red9">{errors.modelo}</Text>
                )}
              </YStack>

              <YStack gap="$2">
                <Text fontWeight="500" color="$gray11">Foto del Zapato *</Text>
                
                {/* Vista previa de la imagen si existe */}
                {foto && (
                  <YStack alignItems="center" gap="$2">
                    <YStack
                      borderWidth={errors.foto ? 2 : 1}
                      borderColor={errors.foto ? "$red9" : "$gray6"}
                      borderRadius={10}
                      padding="$2"
                    >
                      <ZapatoImage 
                        uri={foto}
                        width={120}
                        height={120}
                        borderRadius={8}
                        showErrorText={true}
                      />
                    </YStack>
                    <Button
                      size="$2"
                      backgroundColor="$red9"
                      color="$white1"
                      onPress={() => setFoto("")}
                      pressStyle={{ backgroundColor: "$red10" }}
                    >
                      Eliminar Foto
                    </Button>
                  </YStack>
                )}
                
                {/* Componente para seleccionar imagen */}
                <ImagePickerComponent 
                  onImageSelected={setFoto}
                  disabled={false}
                />
                
                {/* Campo opcional para URL manual */}
                <YStack gap="$1">
                  <Text fontSize="$2" color="$gray10">O ingresa una URL:</Text>
                  <Input
                    value={foto}
                    onChangeText={setFoto}
                    placeholder="https://ejemplo.com/foto.jpg"
                    backgroundColor="$gray2"
                    borderColor={errors.foto ? "$red9" : "$gray6"}
                    focusStyle={{ borderColor: errors.foto ? "$red9" : "$gray9" }}
                    fontSize="$2"
                  />
                </YStack>
                
                {errors.foto && (
                  <Text fontSize="$2" color="$red9">{errors.foto}</Text>
                )}
              </YStack>
            </YStack>
          </Card>

          {/* Precios */}
          <Card 
            padding="$4" 
            backgroundColor="$gray1"
            borderWidth={1}
            borderColor="$gray6"
          >
            <YStack gap="$4">
              <Text fontSize="$4" fontWeight="600" color="$gray12">
                Precios
              </Text>

              <XStack gap="$3">
                <YStack gap="$2" flex={1}>
                  <Text fontWeight="500" color="$gray11">Precio Compra *</Text>
                  <Input
                    value={precioCompra}
                    onChangeText={setPrecioCompra}
                    placeholder="0.00"
                    keyboardType="numeric"
                    backgroundColor="$gray2"
                    borderColor={errors.precioCompra ? "$red9" : "$gray6"}
                    focusStyle={{ borderColor: errors.precioCompra ? "$red9" : "$gray9" }}
                  />
                  {errors.precioCompra && (
                    <Text fontSize="$2" color="$red9">{errors.precioCompra}</Text>
                  )}
                </YStack>

                <YStack gap="$2" flex={1}>
                  <Text fontWeight="500" color="$gray11">Precio Público *</Text>
                  <Input
                    value={precioPublico}
                    onChangeText={setPrecioPublico}
                    placeholder="0.00"
                    keyboardType="numeric"
                    backgroundColor="$gray2"
                    borderColor={errors.precioPublico ? "$red9" : "$gray6"}
                    focusStyle={{ borderColor: errors.precioPublico ? "$red9" : "$gray9" }}
                  />
                  {errors.precioPublico && (
                    <Text fontSize="$2" color="$red9">{errors.precioPublico}</Text>
                  )}
                </YStack>
              </XStack>
              {errors.precios && (
                <Text fontSize="$2" color="$red9">{errors.precios}</Text>
              )}
            </YStack>
          </Card>

          {/* Categoría e Inversionista */}
          <YStack gap="$4">
            <XStack alignItems="center" gap="$2">
              <Text fontSize="$5" fontWeight="700" color="$gray12">
                Clasificación del Producto
              </Text>
            </XStack>

            {/* Categoría */}
            <YStack gap="$3">
              <XStack alignItems="center" gap="$2" justifyContent="space-between">
                <XStack alignItems="center" gap="$2">
                  <Text fontSize="$4" fontWeight="600" color="$gray11">
                    Categoría
                  </Text>
                  <XStack backgroundColor="$gray5" paddingHorizontal="$2" paddingVertical="$0.5" borderRadius="$2">
                    <Text fontSize="$1" color="$gray11" fontWeight="500">
                      OPCIONAL
                    </Text>
                  </XStack>
                </XStack>
                <Button
                  size="$2"
                  circular
                  backgroundColor="$blue10"
                  pressStyle={{ backgroundColor: "$blue11", scale: 0.95 }}
                  onPress={() => setShowCategoryPickerModal(true)}
                >
                  <MaterialIcons name="add" size={20} color="white" />
                </Button>
              </XStack>
              
              {categorias.length === 0 ? (
                <YStack padding="$3" backgroundColor="$gray3" borderRadius="$3" borderWidth={1} borderColor="$gray6">
                  <XStack alignItems="center" justifyContent="center" gap="$2">
                    <Text fontSize="$3" color="$gray8">⚠</Text>
                    <Text textAlign="center" color="$gray10" fontWeight="500">
                      No hay categorías disponibles
                    </Text>
                  </XStack>
                </YStack>
              ) : (
                <XStack flexWrap="wrap" gap="$2">
                  <Button
                    size="$3"
                    backgroundColor={!categoriaId ? "$gray11" : "$gray4"}
                    borderWidth={1}
                    borderColor={!categoriaId ? "$gray12" : "$gray6"}
                    borderRadius="$2"
                    pressStyle={{
                      backgroundColor: !categoriaId ? "$gray12" : "$gray5",
                      scale: 0.98
                    }}
                    onPress={() => setCategoriaId("")}
                    paddingHorizontal="$3"
                  >
                    <XStack alignItems="center" gap="$1">
                      {!categoriaId && <Text color="white" fontSize="$3">✓</Text>}
                      <Text 
                        color={!categoriaId ? "white" : "$gray10"} 
                        fontSize="$3" 
                        fontWeight={!categoriaId ? "600" : "500"}
                      >
                        Sin categoría
                      </Text>
                    </XStack>
                  </Button>
                  
                  {categorias.map((categoria) => (
                    <Button
                      key={categoria.id}
                      size="$3"
                      backgroundColor={categoriaId === categoria.id ? "$gray11" : "$gray4"}
                      borderWidth={1}
                      borderColor={categoriaId === categoria.id ? "$gray12" : "$gray6"}
                      borderRadius="$2"
                      pressStyle={{
                        backgroundColor: categoriaId === categoria.id ? "$gray12" : "$gray5",
                        scale: 0.98
                      }}
                      onPress={() => setCategoriaId(categoria.id)}
                      paddingHorizontal="$3"
                    >
                      <XStack alignItems="center" gap="$1">
                        {categoriaId === categoria.id && <Text color="white" fontSize="$3">✓</Text>}
                        <Text 
                          color={categoriaId === categoria.id ? "white" : "$gray10"} 
                            fontSize="$3" 
                            fontWeight={categoriaId === categoria.id ? "600" : "500"}
                          >
                            {categoria.nombre}
                          </Text>
                        </XStack>
                      </Button>
                    ))}
                  </XStack>
              )}
            </YStack>

            <Separator backgroundColor="$gray6" />

              {/* Inversionista */}
              <YStack gap="$3">
                <XStack alignItems="center" gap="$2">
                  <Text fontSize="$4" fontWeight="600" color="$gray11">
                    Inversionista
                  </Text>
                  <Card backgroundColor="$gray12" paddingHorizontal="$2" paddingVertical="$0.5" borderRadius="$2">
                    <Text fontSize="$1" color="white" fontWeight="600">
                      REQUERIDO
                    </Text>
                  </Card>
                  <Button
                    size="$2"
                    circular
                    backgroundColor="$green10"
                    pressStyle={{ backgroundColor: "$green11", scale: 0.95 }}
                    onPress={() => setShowInversionistaModal(true)}
                  >
                    <MaterialIcons name="add" size={20} color="white" />
                  </Button>
                </XStack>
                
                {inversionistas.length === 0 ? (
                  <Card padding="$3" backgroundColor="$gray3" borderRadius="$3" borderWidth={1} borderColor="$gray7">
                    <XStack alignItems="center" justifyContent="center" gap="$2">
                      <Text fontSize="$3" color="$gray8">⚠</Text>
                      <Text textAlign="center" color="$gray10" fontWeight="500">
                        No hay inversionistas disponibles
                      </Text>
                    </XStack>
                  </Card>
                ) : (
                  <YStack gap="$2">
                    {inversionistas.map((inversionista, index) => (
                      <Button
                        key={inversionista.id}
                        backgroundColor={inversionistaId === inversionista.id ? "$gray11" : "$gray3"}
                        borderWidth={1}
                        borderColor={inversionistaId === inversionista.id ? "$gray12" : "$gray6"}
                        borderRadius="$3"
                        padding="$3"
                        pressStyle={{
                          backgroundColor: inversionistaId === inversionista.id ? "$gray12" : "$gray4",
                          scale: 0.98,
                          borderColor: inversionistaId === inversionista.id ? "$gray12" : "$gray7",
                        }}
                        onPress={() => setInversionistaId(inversionista.id)}
                        justifyContent="flex-start"
                      >
                        <XStack alignItems="center" gap="$3" flex={1}>
                          <XStack 
                            width={32} 
                            height={32} 
                            alignItems="center" 
                            justifyContent="center"
                            backgroundColor={inversionistaId === inversionista.id ? "white" : "$gray7"}
                            borderRadius="$2"
                            borderWidth={1}
                            borderColor={inversionistaId === inversionista.id ? "$gray4" : "$gray8"}
                          >
                            {inversionistaId === inversionista.id ? (
                              <Text color="$gray12" fontSize="$4" fontWeight="700">✓</Text>
                            ) : (
                              <Text color="$gray10" fontSize="$3" fontWeight="600">
                                {index + 1}
                              </Text>
                            )}
                          </XStack>
                          <YStack flex={1}>
                            <Text 
                              fontSize="$4" 
                              fontWeight="600"
                              color={inversionistaId === inversionista.id ? "white" : "$gray12"}
                            >
                              {inversionista.nombre}
                            </Text>
                            <Text 
                              fontSize="$2" 
                              color={inversionistaId === inversionista.id ? "$gray4" : "$gray9"}
                            >
                              {inversionistaId === inversionista.id ? "Seleccionado" : "Presiona para seleccionar"}
                            </Text>
                          </YStack>
                        </XStack>
                      </Button>
                    ))}
                  </YStack>
                )}
                
                {errors.inversionista && (
                  <Card padding="$2" backgroundColor="$gray3" borderRadius="$2" borderWidth={1} borderColor="$gray7">
                    <XStack alignItems="center" gap="$2">
                      <Text fontSize="$3" color="$gray8">⚠</Text>
                      <Text fontSize="$3" color="$gray10" fontWeight="500">
                        {errors.inversionista}
                      </Text>
                    </XStack>
                  </Card>
                )}
              </YStack>
            </YStack>

          {/* Medidas */}
          <Card 
            padding="$4" 
            backgroundColor="$gray1"
            borderWidth={1}
            borderColor="$gray6"
          >
            <YStack gap="$4">
              <Text fontSize="$4" fontWeight="600" color="$gray12">
                Rango de Medidas
              </Text>

              <XStack gap="$3">
                <YStack gap="$2" flex={1}>
                  <Text fontWeight="500" color="$gray11">Medida Inicial *</Text>
                  <Input
                    value={medidaInicio}
                    onChangeText={setMedidaInicio}
                    placeholder="22.0"
                    keyboardType="numeric"
                    backgroundColor="$gray2"
                    borderColor={errors.medidaInicio ? "$red9" : "$gray6"}
                    focusStyle={{ borderColor: errors.medidaInicio ? "$red9" : "$gray9" }}
                  />
                  {errors.medidaInicio && (
                    <Text fontSize="$2" color="$red9">{errors.medidaInicio}</Text>
                  )}
                </YStack>

                <YStack gap="$2" flex={1}>
                  <Text fontWeight="500" color="$gray11">Medida Final *</Text>
                  <Input
                    value={medidaFin}
                    onChangeText={setMedidaFin}
                    placeholder="28.0"
                    keyboardType="numeric"
                    backgroundColor="$gray2"
                    borderColor={errors.medidaFin ? "$red9" : "$gray6"}
                    focusStyle={{ borderColor: errors.medidaFin ? "$red9" : "$gray9" }}
                  />
                  {errors.medidaFin && (
                    <Text fontSize="$2" color="$red9">{errors.medidaFin}</Text>
                  )}
                </YStack>
              </XStack>
              {errors.medidaRango && (
                <Text fontSize="$2" color="$red9">{errors.medidaRango}</Text>
              )}
            </YStack>
          </Card>

          {/* Colores */}
          <YStack gap="$4">
            <XStack justifyContent="space-between" alignItems="center">
              <XStack alignItems="center" gap="$2">
                <Text fontSize="$5" fontWeight="700" color="$gray12">
                  Colores *
                </Text>
                <YStack backgroundColor="$blue9" paddingHorizontal="$2" paddingVertical="$0.5" borderRadius="$2">
                  <Text fontSize="$1" color="white" fontWeight="600">
                    REQUERIDO
                  </Text>
                </YStack>
              </XStack>
              <Button
                size="$2"
                circular
                backgroundColor="$blue10"
                pressStyle={{ backgroundColor: "$blue11", scale: 0.95 }}
                onPress={() => setShowColorPickerModal(true)}
              >
                <MaterialIcons name="add" size={20} color="white" />
              </Button>
            </XStack>

            {availableColors.length === 0 ? (
              <YStack padding="$3" backgroundColor="$gray3" borderRadius="$3" borderWidth={1} borderColor="$gray6">
                <XStack alignItems="center" justifyContent="center" gap="$2">
                  <Text fontSize="$3" color="$gray8">⚠</Text>
                  <Text textAlign="center" color="$gray10" fontWeight="500">
                    No hay colores disponibles. Crea uno nuevo.
                  </Text>
                </XStack>
              </YStack>
            ) : (
              <YStack gap="$2">
                <XStack flexWrap="wrap" gap="$2">
                  {availableColors.map((color) => (
                    <Button
                      key={color.id}
                      size="$3"
                      backgroundColor={selectedColorIds.includes(color.id) ? "$blue9" : "$gray3"}
                      borderWidth={2}
                      borderColor={selectedColorIds.includes(color.id) ? "$blue11" : "$gray6"}
                      borderRadius="$3"
                      pressStyle={{
                        backgroundColor: selectedColorIds.includes(color.id) ? "$blue10" : "$gray4",
                        scale: 0.98
                      }}
                      onPress={() => toggleColorSelection(color.id)}
                      paddingHorizontal="$3"
                    >
                      <XStack alignItems="center" gap="$2">
                        <ColorCircle color={color} size={24} />
                        <Text 
                          color={selectedColorIds.includes(color.id) ? "white" : "$gray11"} 
                          fontSize="$3" 
                          fontWeight={selectedColorIds.includes(color.id) ? "600" : "500"}
                        >
                          {color.nombre}
                        </Text>
                        {selectedColorIds.includes(color.id) && <Text color="white" fontSize="$3">✓</Text>}
                      </XStack>
                    </Button>
                  ))}
                </XStack>
              </YStack>
            )}

            {errors.colores && (
              <Text fontSize="$2" color="$red9">{errors.colores}</Text>
            )}
          </YStack>

          {/* Vista previa */}
          <Card 
            padding="$4" 
            backgroundColor="$gray2"
            borderWidth={1}
            borderColor="$gray6"
          >
            <YStack gap="$3">
              <Text fontSize="$4" fontWeight="600" color="$gray12">
                Resumen
              </Text>

              <YStack gap="$2">
                <XStack justifyContent="space-between">
                  <Text color="$gray10" fontWeight="500">Código:</Text>
                  <Text fontWeight="600" color="$gray12">{codigoBarras || "Sin especificar"}</Text>
                </XStack>

                <XStack justifyContent="space-between">
                  <Text color="$gray10" fontWeight="500">Nombre:</Text>
                  <Text fontWeight="600" color="$gray12">{nombre || "Sin especificar"}</Text>
                </XStack>

                <XStack justifyContent="space-between">
                  <Text color="$gray10" fontWeight="500">Rango:</Text>
                  <Text fontWeight="600" color="$gray12">
                    {medidaInicio && medidaFin ? `${medidaInicio} - ${medidaFin}` : "Sin especificar"}
                  </Text>
                </XStack>

                <XStack justifyContent="space-between">
                  <Text color="$gray10" fontWeight="500">Precio:</Text>
                  <Text fontWeight="600" color="$gray12">
                    {precioPublico ? `$${precioPublico}` : "Sin especificar"}
                  </Text>
                </XStack>
              </YStack>
            </YStack>
          </Card>
        </YStack>
      </ScrollView>

      {/* Botones de acción fijos */}
      <YStack
        padding="$4"
        paddingTop="$3"
        backgroundColor="white"
        borderTopWidth={1}
        borderTopColor="$gray6"
        shadowColor="$gray8"
        shadowOffset={{ width: 0, height: -2 }}
        shadowOpacity={0.1}
        shadowRadius={4}
      >
        <XStack gap="$3">
          <Button 
            variant="outlined"
            borderWidth={1}
            borderColor="$gray7"
            backgroundColor="white"
            onPress={onCancel} 
            flex={1}
            size="$4"
            borderRadius="$3"
            pressStyle={{ 
              backgroundColor: "$gray2",
              borderColor: "$gray8",
              scale: 0.98
            }}
          >
            <Text fontWeight="600" color="$gray11" fontSize="$3">
              Cancelar
            </Text>
          </Button>
          
          <Button
            backgroundColor="$gray12"
            borderWidth={1}
            borderColor="$gray12"
            onPress={handleSave}
            flex={2}
            size="$4"
            borderRadius="$3"
            disabled={!codigoBarras.trim() || !nombre.trim() || !modelo.trim() || !inversionistaId.trim()}
            pressStyle={{ 
              backgroundColor: "$gray11",
              borderColor: "$gray11",
              scale: 0.98
            }}
            disabledStyle={{ 
              backgroundColor: "$gray6",
              borderColor: "$gray6",
              opacity: 0.5
            }}
          >
            <Text fontWeight="700" color="white" fontSize="$3">
              {initialZapato ? "Actualizar Zapato" : "Crear Zapato"}
            </Text>
          </Button>
        </XStack>
        
        {(!codigoBarras.trim() || !nombre.trim() || !modelo.trim() || !inversionistaId.trim()) && (
          <XStack alignItems="center" justifyContent="center" gap="$2" marginTop="$3" padding="$2">
            <Text fontSize="$2" color="$gray8">⚠</Text>
            <Text fontSize="$2" color="$gray9" textAlign="center">
              Complete todos los campos obligatorios para continuar
            </Text>
          </XStack>
        )}
      </YStack>

      {/* Scanner de código de barras */}
      <BarcodeScanner
        visible={showBarcodeScanner}
        onClose={() => setShowBarcodeScanner(false)}
        onScan={handleBarcodeScanned}
      />

      {/* Modal de color picker para crear nuevo color */}
      <ColorPickerModal
        visible={showColorPickerModal}
        onClose={() => setShowColorPickerModal(false)}
        onColorCreated={handleColorCreated}
      />

      {/* Modal de category picker para crear nueva categoría */}
      <CategoryPickerModal
        visible={showCategoryPickerModal}
        onClose={() => setShowCategoryPickerModal(false)}
        onCategoryCreated={handleCategoryCreated}
      />

      {/* Modal para crear nuevo inversionista */}
      <Sheet
        modal
        open={showInversionistaModal}
        onOpenChange={setShowInversionistaModal}
        snapPointsMode="fit"
      >
        <Sheet.Overlay />
        <Sheet.Frame padding="$4">
          {creatingInversionista ? (
            <Text textAlign="center">Creando inversionista...</Text>
          ) : (
            <InversionistaForm
              initialInversionista={null}
              onSave={handleInversionistaCreated}
              onCancel={() => setShowInversionistaModal(false)}
            />
          )}
        </Sheet.Frame>
      </Sheet>
    </YStack>
  );
};