import React, { useState, useEffect } from "react";
import { View, ScrollView, Dimensions } from "react-native";
import {
  YStack,
  XStack,
  Text,
  Button,
  Input,
  Card,
  H5,
  Separator,
  Slider,
} from "tamagui";
import { Color } from "../types";
import { ColorCircle } from "./ColorCircle";

const { height: screenHeight } = Dimensions.get("window");

// Funciones de conversión de colores
const hexToRgb = (hex: string) => {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : { r: 255, g: 0, b: 0 };
};

const rgbToHex = (r: number, g: number, b: number) => {
  return "#" + ((1 << 24) + (Math.round(r) << 16) + (Math.round(g) << 8) + Math.round(b)).toString(16).slice(1);
};

// Componente reutilizable para el color picker con sliders
const RGBColorPicker: React.FC<{
  color: string;
  onColorChange: (color: string) => void;
  title: string;
}> = ({ color, onColorChange, title }) => {
  const rgb = hexToRgb(color);
  
  return (
    <Card padding="$3" backgroundColor="$background">
      <YStack gap="$3">
        <Text fontSize="$3" textAlign="center">{title}</Text>
        
        {/* Vista previa del color */}
        <View
          style={{
            width: "100%",
            height: 50,
            backgroundColor: color,
            borderRadius: 8,
            borderWidth: 1,
            borderColor: "#ddd",
          }}
        />
        
        {/* Sliders RGB */}
        <YStack gap="$2">
          <YStack gap="$1">
            <Text fontSize="$2" color="#FF0000">Rojo: {Math.round(rgb.r)}</Text>
            <Slider
              size="$4"
              width="100%"
              value={[rgb.r]}
              min={0}
              max={255}
              step={1}
              onValueChange={([value]) => {
                const newRgb = { ...rgb, r: value };
                onColorChange(rgbToHex(newRgb.r, newRgb.g, newRgb.b));
              }}
            >
              <Slider.Track backgroundColor="#FFD0D0">
                <Slider.TrackActive backgroundColor="#FF0000" />
              </Slider.Track>
              <Slider.Thumb index={0} backgroundColor="#FF0000" />
            </Slider>
          </YStack>
          
          <YStack gap="$1">
            <Text fontSize="$2" color="#00AA00">Verde: {Math.round(rgb.g)}</Text>
            <Slider
              size="$4"
              width="100%"
              value={[rgb.g]}
              min={0}
              max={255}
              step={1}
              onValueChange={([value]) => {
                const newRgb = { ...rgb, g: value };
                onColorChange(rgbToHex(newRgb.r, newRgb.g, newRgb.b));
              }}
            >
              <Slider.Track backgroundColor="#D0FFD0">
                <Slider.TrackActive backgroundColor="#00AA00" />
              </Slider.Track>
              <Slider.Thumb index={0} backgroundColor="#00AA00" />
            </Slider>
          </YStack>
          
          <YStack gap="$1">
            <Text fontSize="$2" color="#0000FF">Azul: {Math.round(rgb.b)}</Text>
            <Slider
              size="$4"
              width="100%"
              value={[rgb.b]}
              min={0}
              max={255}
              step={1}
              onValueChange={([value]) => {
                const newRgb = { ...rgb, b: value };
                onColorChange(rgbToHex(newRgb.r, newRgb.g, newRgb.b));
              }}
            >
              <Slider.Track backgroundColor="#D0D0FF">
                <Slider.TrackActive backgroundColor="#0000FF" />
              </Slider.Track>
              <Slider.Thumb index={0} backgroundColor="#0000FF" />
            </Slider>
          </YStack>
        </YStack>
        
        <Text fontSize="$2" textAlign="center" color="$gray10">
          {color.toUpperCase()}
        </Text>
      </YStack>
    </Card>
  );
};

interface AdvancedColorPickerProps {
  initialColor?: Color | null;
  onSave: (colorData: Omit<Color, "id" | "createdAt" | "updatedAt">) => void;
  onCancel: () => void;
}

export const AdvancedColorPicker: React.FC<AdvancedColorPickerProps> = ({
  initialColor,
  onSave,
  onCancel,
}) => {
  const [nombre, setNombre] = useState(initialColor?.nombre || "");
  const [colorType, setColorType] = useState<"simple" | "combo">(
    initialColor?.isCombo ? "combo" : "simple"
  );
  const [simpleColor, setSimpleColor] = useState(
    initialColor?.hexadecimal || "#FF0000"
  );
  const [primaryColor, setPrimaryColor] = useState(
    initialColor?.primaryColor || "#FF0000"
  );
  const [secondaryColor, setSecondaryColor] = useState(
    initialColor?.secondaryColor || "#0000FF"
  );
  const [showSimplePicker, setShowSimplePicker] = useState(false);
  const [showPrimaryPicker, setShowPrimaryPicker] = useState(false);
  const [showSecondaryPicker, setShowSecondaryPicker] = useState(false);

  // Actualizar estados cuando cambia initialColor
  useEffect(() => {
    console.log("AdvancedColorPicker - initialColor changed:", initialColor);
    
    if (initialColor) {
      // Edición - cargar datos del color existente
      setNombre(initialColor.nombre || "");
      setColorType(initialColor.isCombo ? "combo" : "simple");
      
      if (initialColor.isCombo) {
        // Es una combinación
        setPrimaryColor(initialColor.primaryColor || "#FF0000");
        setSecondaryColor(initialColor.secondaryColor || "#0000FF");
        setSimpleColor("#FF0000"); // valor por defecto para simple
      } else {
        // Es color simple
        setSimpleColor(initialColor.hexadecimal || "#FF0000");
        setPrimaryColor("#FF0000"); // valores por defecto para combo
        setSecondaryColor("#0000FF");
      }
    } else {
      // Creación - valores por defecto
      setNombre("");
      setColorType("simple");
      setSimpleColor("#FF0000");
      setPrimaryColor("#FF0000");
      setSecondaryColor("#0000FF");
    }
    
    // Cerrar todos los pickers al cambiar
    setShowSimplePicker(false);
    setShowPrimaryPicker(false);
    setShowSecondaryPicker(false);
  }, [initialColor]);

  const handleSave = () => {
    if (!nombre.trim()) {
      return;
    }

    const colorData = {
      nombre: nombre.trim(),
      isCombo: colorType === "combo",
      hexadecimal: colorType === "simple" ? simpleColor : undefined,
      primaryColor: colorType === "combo" ? primaryColor : undefined,
      secondaryColor: colorType === "combo" ? secondaryColor : undefined,
    };

    onSave(colorData);
  };

  // Vista previa del color
  const previewColor: Color = {
    id: "preview",
    nombre,
    hexadecimal: colorType === "simple" ? simpleColor : undefined,
    isCombo: colorType === "combo",
    primaryColor: colorType === "combo" ? primaryColor : undefined,
    secondaryColor: colorType === "combo" ? secondaryColor : undefined,
    createdAt: "",
    updatedAt: "",
  };

  return (
    <YStack flex={1} height={screenHeight * 0.85}>
      <YStack padding="$4" paddingBottom="$2" backgroundColor="$background">
        <H5 textAlign="center" color="$gray12" fontWeight="600">
          {initialColor ? "Editar Color" : "Nuevo Color"}
        </H5>
      </YStack>
      
      <ScrollView 
        style={{ flex: 1 }}
        contentContainerStyle={{ 
          paddingHorizontal: 16, 
          paddingBottom: 20,
          minHeight: 400 
        }}
        showsVerticalScrollIndicator={true}
        bounces={true}
      >
        <YStack gap="$4" paddingVertical="$3">

      {/* Vista previa */}
      <Card 
        padding="$3" 
        alignItems="center"
        backgroundColor="$gray1"
        borderWidth={1}
        borderColor="$gray6"
      >
        <Text marginBottom="$2" fontWeight="500" color="$gray11">Vista Previa:</Text>
        <ColorCircle color={previewColor} size={80} showName />
      </Card>

      {/* Nombre del color */}
      <YStack gap="$2">
        <Text fontWeight="600" color="$gray11">Nombre del Color *</Text>
        <Input
          value={nombre}
          onChangeText={setNombre}
          placeholder="Ingrese el nombre del color"
          backgroundColor="$gray2"
          borderColor="$gray6"
          focusStyle={{ borderColor: "$gray9" }}
        />
      </YStack>

      <Separator />

      {/* Selector de tipo */}
      <YStack gap="$3">
        <Text fontWeight="600" color="$gray11">Tipo de Color</Text>
        <XStack gap="$4">
          <Button
            size="$3"
            backgroundColor={colorType === "simple" ? "$gray12" : "$gray6"}
            color={colorType === "simple" ? "$gray1" : "$gray12"}
            borderColor={colorType === "simple" ? "$gray12" : "$gray8"}
            onPress={() => {
              setColorType("simple");
              setShowSimplePicker(false);
              setShowPrimaryPicker(false);
              setShowSecondaryPicker(false);
            }}
            flex={1}
            pressStyle={{ backgroundColor: colorType === "simple" ? "$gray11" : "$gray7" }}
          >
            Color Simple
          </Button>
          <Button
            size="$3"
            backgroundColor={colorType === "combo" ? "$gray12" : "$gray6"}
            color={colorType === "combo" ? "$gray1" : "$gray12"}
            borderColor={colorType === "combo" ? "$gray12" : "$gray8"}
            onPress={() => {
              setColorType("combo");
              setShowSimplePicker(false);
              setShowPrimaryPicker(false);
              setShowSecondaryPicker(false);
            }}
            flex={1}
            pressStyle={{ backgroundColor: colorType === "combo" ? "$gray11" : "$gray7" }}
          >
            Combinación
          </Button>
        </XStack>
      </YStack>

      <Separator />

      {/* Configuración de colores según el tipo */}
      {colorType === "simple" ? (
        <YStack gap="$3">
          <Text fontWeight="600" color="$gray11">Seleccionar Color</Text>
          
          {/* Botón de color actual */}
          <XStack alignItems="center" gap="$3">
            <View
              style={{
                width: 50,
                height: 50,
                backgroundColor: simpleColor,
                borderRadius: 25,
                borderWidth: 2,
                borderColor: "#ccc",
              }}
            />
            <YStack flex={1}>
              <Text fontSize="$3" fontWeight="600" color="$gray12">{simpleColor.toUpperCase()}</Text>
              <Text fontSize="$2" color="$gray10">Utilice los controles para personalizar</Text>
            </YStack>
          </XStack>

          {/* Color Picker Visual */}
          {showSimplePicker ? (
            <Card padding="$3" backgroundColor="$background">
              <YStack gap="$3">
                <Text fontSize="$3" textAlign="center">Selector de Color Visual</Text>
                
                {/* Vista previa del color */}
                <View
                  style={{
                    width: "100%",
                    height: 60,
                    backgroundColor: simpleColor,
                    borderRadius: 10,
                    borderWidth: 1,
                    borderColor: "#ddd",
                  }}
                />
                
                {/* Sliders RGB */}
                <YStack gap="$3">
                  {(() => {
                    const rgb = hexToRgb(simpleColor);
                    return (
                      <>
                        <YStack gap="$2">
                          <Text fontSize="$3" color="#FF0000">Rojo: {Math.round(rgb.r)}</Text>
                          <Slider
                            size="$4"
                            width="100%"
                            value={[rgb.r]}
                            min={0}
                            max={255}
                            step={1}
                            onValueChange={([value]) => {
                              const newRgb = { ...rgb, r: value };
                              setSimpleColor(rgbToHex(newRgb.r, newRgb.g, newRgb.b));
                            }}
                          >
                            <Slider.Track backgroundColor="#FFD0D0">
                              <Slider.TrackActive backgroundColor="#FF0000" />
                            </Slider.Track>
                            <Slider.Thumb index={0} backgroundColor="#FF0000" />
                          </Slider>
                        </YStack>
                        
                        <YStack gap="$2">
                          <Text fontSize="$3" color="#00AA00">Verde: {Math.round(rgb.g)}</Text>
                          <Slider
                            size="$4"
                            width="100%"
                            value={[rgb.g]}
                            min={0}
                            max={255}
                            step={1}
                            onValueChange={([value]) => {
                              const newRgb = { ...rgb, g: value };
                              setSimpleColor(rgbToHex(newRgb.r, newRgb.g, newRgb.b));
                            }}
                          >
                            <Slider.Track backgroundColor="#D0FFD0">
                              <Slider.TrackActive backgroundColor="#00AA00" />
                            </Slider.Track>
                            <Slider.Thumb index={0} backgroundColor="#00AA00" />
                          </Slider>
                        </YStack>
                        
                        <YStack gap="$2">
                          <Text fontSize="$3" color="#0000FF">Azul: {Math.round(rgb.b)}</Text>
                          <Slider
                            size="$4"
                            width="100%"
                            value={[rgb.b]}
                            min={0}
                            max={255}
                            step={1}
                            onValueChange={([value]) => {
                              const newRgb = { ...rgb, b: value };
                              setSimpleColor(rgbToHex(newRgb.r, newRgb.g, newRgb.b));
                            }}
                          >
                            <Slider.Track backgroundColor="#D0D0FF">
                              <Slider.TrackActive backgroundColor="#0000FF" />
                            </Slider.Track>
                            <Slider.Thumb index={0} backgroundColor="#0000FF" />
                          </Slider>
                        </YStack>
                      </>
                    );
                  })()}
                </YStack>
                
                <Text fontSize="$2" textAlign="center" color="$gray10">
                  Color: {simpleColor.toUpperCase()}
                </Text>
                
                <Button 
                  theme="blue" 
                  onPress={() => setShowSimplePicker(false)}
                >
                  ✓ Usar Este Color
                </Button>
              </YStack>
            </Card>
          ) : (
            <YStack gap="$3">
              {/* Input manual del color */}
              <YStack gap="$2">
                <Text fontSize="$3">Código del Color (Hex):</Text>
                <Input
                  value={simpleColor}
                  onChangeText={(text) => {
                    // Asegurar que empiece con # y tenga formato válido
                    let cleanText = text.replace(/[^#0-9A-Fa-f]/g, '');
                    if (!cleanText.startsWith('#')) {
                      cleanText = '#' + cleanText;
                    }
                    if (cleanText.length <= 7) {
                      setSimpleColor(cleanText);
                    }
                  }}
                  placeholder="#FF0000"
                  maxLength={7}
                />
              </YStack>

              {/* Botón para abrir picker visual */}
              <Button 
                theme="blue" 
                onPress={() => setShowSimplePicker(true)}
                size="$4"
              >
                🎨 Abrir Selector Visual de Color
              </Button>

              {/* Colores predefinidos */}
              <YStack gap="$2">
                <Text fontSize="$3">Colores Rápidos:</Text>
                <XStack gap="$2" flexWrap="wrap">
                  {["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF", "#FFA500", "#800080", "#FFC0CB", "#000000", "#FFFFFF", "#808080"].map((color) => (
                    <View
                      key={color}
                      style={{
                        width: 40,
                        height: 40,
                        backgroundColor: color,
                        borderRadius: 20,
                        borderWidth: simpleColor === color ? 3 : 1,
                        borderColor: simpleColor === color ? "#007AFF" : "#ddd",
                        margin: 2,
                      }}
                      onTouchEnd={() => setSimpleColor(color)}
                    />
                  ))}
                </XStack>
              </YStack>
            </YStack>
          )}
        </YStack>
      ) : (
        <YStack gap="$4">
          <Text fontWeight="bold">Seleccionar Colores de la Combinación</Text>
          
          {/* Color Primario */}
          <YStack gap="$2">
            <Text fontSize="$4" fontWeight="600">Color Primario</Text>
            <XStack alignItems="center" gap="$3">
              <View
                style={{
                  width: 40,
                  height: 40,
                  backgroundColor: primaryColor,
                  borderRadius: 20,
                  borderWidth: 2,
                  borderColor: "#ddd",
                }}
              />
              <YStack flex={1}>
                <Text fontSize="$2" fontWeight="bold">{primaryColor.toUpperCase()}</Text>
              </YStack>
            </XStack>

            {showPrimaryPicker ? (
              <YStack gap="$3">
                <RGBColorPicker
                  color={primaryColor}
                  onColorChange={setPrimaryColor}
                  title="Color Primario - Selector Visual"
                />
                <Button 
                  theme="blue" 
                  onPress={() => setShowPrimaryPicker(false)}
                >
                  ✓ Usar Este Color Primario
                </Button>
              </YStack>
            ) : (
              <YStack gap="$2">
                <Text fontSize="$2">Código Hex del Color Primario:</Text>
                <Input
                  value={primaryColor}
                  onChangeText={(text) => {
                    let cleanText = text.replace(/[^#0-9A-Fa-f]/g, '');
                    if (!cleanText.startsWith('#')) {
                      cleanText = '#' + cleanText;
                    }
                    if (cleanText.length <= 7) {
                      setPrimaryColor(cleanText);
                    }
                  }}
                  placeholder="#FF0000"
                  maxLength={7}
                />
                <Button 
                  size="$2"
                  theme="blue"
                  onPress={() => setShowPrimaryPicker(true)}
                >
                  🎨 Selector Visual
                </Button>
                <XStack gap="$2" flexWrap="wrap">
                  {["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"].map((color) => (
                    <View
                      key={color}
                      style={{
                        width: 30,
                        height: 30,
                        backgroundColor: color,
                        borderRadius: 15,
                        borderWidth: primaryColor === color ? 2 : 1,
                        borderColor: primaryColor === color ? "#007AFF" : "#ddd",
                        margin: 1,
                      }}
                      onTouchEnd={() => setPrimaryColor(color)}
                    />
                  ))}
                </XStack>
              </YStack>
            )}
          </YStack>

          {/* Color Secundario */}
          <YStack gap="$2">
            <Text fontSize="$4" fontWeight="600">Color Secundario</Text>
            <XStack alignItems="center" gap="$3">
              <View
                style={{
                  width: 40,
                  height: 40,
                  backgroundColor: secondaryColor,
                  borderRadius: 20,
                  borderWidth: 2,
                  borderColor: "#ddd",
                }}
              />
              <YStack flex={1}>
                <Text fontSize="$2" fontWeight="bold">{secondaryColor.toUpperCase()}</Text>
              </YStack>
            </XStack>

            {showSecondaryPicker ? (
              <YStack gap="$3">
                <RGBColorPicker
                  color={secondaryColor}
                  onColorChange={setSecondaryColor}
                  title="Color Secundario - Selector Visual"
                />
                <Button 
                  theme="blue" 
                  onPress={() => setShowSecondaryPicker(false)}
                >
                  ✓ Usar Este Color Secundario
                </Button>
              </YStack>
            ) : (
              <YStack gap="$2">
                <Text fontSize="$2">Código Hex del Color Secundario:</Text>
                <Input
                  value={secondaryColor}
                  onChangeText={(text) => {
                    let cleanText = text.replace(/[^#0-9A-Fa-f]/g, '');
                    if (!cleanText.startsWith('#')) {
                      cleanText = '#' + cleanText;
                    }
                    if (cleanText.length <= 7) {
                      setSecondaryColor(cleanText);
                    }
                  }}
                  placeholder="#0000FF"
                  maxLength={7}
                />
                <Button 
                  size="$2"
                  theme="blue"
                  onPress={() => setShowSecondaryPicker(true)}
                >
                  🎨 Selector Visual
                </Button>
                <XStack gap="$2" flexWrap="wrap">
                  {["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"].map((color) => (
                    <View
                      key={color}
                      style={{
                        width: 30,
                        height: 30,
                        backgroundColor: color,
                        borderRadius: 15,
                        borderWidth: secondaryColor === color ? 2 : 1,
                        borderColor: secondaryColor === color ? "#007AFF" : "#ddd",
                        margin: 1,
                      }}
                      onTouchEnd={() => setSecondaryColor(color)}
                    />
                  ))}
                </XStack>
              </YStack>
            )}
          </YStack>
        </YStack>
      )}

        </YStack>
      </ScrollView>
      
      {/* Botones de acción fijos en la parte inferior */}
      <YStack 
        padding="$4" 
        paddingTop="$3" 
        backgroundColor="$background"
        borderTopWidth={1}
        borderTopColor="$borderColor"
      >
        <XStack gap="$3">
          <Button 
            backgroundColor="$gray6" 
            color="$gray12"
            borderColor="$gray8"
            onPress={onCancel} 
            flex={1}
            pressStyle={{ backgroundColor: "$gray7" }}
          >
            Cancelar
          </Button>
          <Button 
            backgroundColor="$gray12"
            color="$gray1"
            borderColor="$gray12"
            onPress={handleSave} 
            flex={1}
            disabled={!nombre.trim()}
            pressStyle={{ backgroundColor: "$gray11" }}
            disabledStyle={{ backgroundColor: "$gray8" }}
          >
            Guardar Color
          </Button>
        </XStack>
      </YStack>
    </YStack>
  );
};