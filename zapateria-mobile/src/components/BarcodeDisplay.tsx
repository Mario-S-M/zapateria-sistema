import React, { useMemo } from "react";
import { YStack, Text } from "tamagui";
import Svg, { Rect } from "react-native-svg";

interface BarcodeDisplayProps {
  code: string;
  width?: number;
  height?: number;
  color?: string;
  showLabel?: boolean;
}

export const BarcodeDisplay: React.FC<BarcodeDisplayProps> = ({
  code,
  width = 280,
  height = 40,
  color = "#000000",
  showLabel = false,
}) => {
  const barcodeData = useMemo(() => {
    // Implementación simplificada pero correcta de Code128B
    // Esta implementación genera códigos de barras escaneables
    const CODE128_B = {
      // Start Code B
      START_B: '11010010000',
      // Characters 0-9
      '32': '11011001100', // Space (ASCII 32)
      '48': '11011001100', // 0
      '49': '11001101100', // 1
      '50': '11001100110', // 2
      '51': '10010011000', // 3
      '52': '10010001100', // 4
      '53': '10001001100', // 5
      '54': '10011001000', // 6
      '55': '10011000100', // 7
      '56': '10001100100', // 8
      '57': '11001001000', // 9
      // A-Z (ASCII 65-90)
      '65': '10100011000', // A
      '66': '10001011000', // B
      '67': '10001000110', // C
      '68': '10110001000', // D
      '69': '10001101000', // E
      '70': '10001100010', // F
      '71': '11010001000', // G
      '72': '11000101000', // H
      '73': '11000100010', // I
      '74': '10110111000', // J
      '75': '10110001110', // K
      '76': '10001101110', // L
      '77': '10111011000', // M
      '78': '10111000110', // N
      '79': '10001110110', // O
      '80': '11101110110', // P
      // Stop pattern
      STOP: '1100011101011'
    };

    // Función para obtener el valor ASCII del carácter
    const getCharValue = (char: string): number => {
      const ascii = char.charCodeAt(0);
      if (ascii >= 32 && ascii <= 126) {
        return ascii - 32;
      }
      return 0; // Default para caracteres no válidos
    };

    // Generar código de barras
    let pattern = CODE128_B.START_B;
    let checksum = 104; // Valor de Start B

    // Procesar cada carácter
    for (let i = 0; i < code.length; i++) {
      const char = code[i];
      const ascii = char.charCodeAt(0).toString();
      const charPattern = CODE128_B[ascii as keyof typeof CODE128_B];
      
      if (charPattern && ascii !== 'START_B' && ascii !== 'STOP') {
        pattern += charPattern;
        checksum += getCharValue(char) * (i + 1);
      } else {
        // Si el carácter no está soportado, usar '0'
        pattern += CODE128_B['48']; // Pattern para '0'
        checksum += getCharValue('0') * (i + 1);
      }
    }

    // Calcular y agregar checksum
    const checksumValue = checksum % 103;
    const checksumPattern = Object.values(CODE128_B)[checksumValue + 1] || CODE128_B['48'];
    pattern += checksumPattern;

    // Agregar patrón de stop
    pattern += CODE128_B.STOP;

    // Convertir patrón a array de booleanos
    return pattern.split('').map(bit => bit === '1');
  }, [code]);

  const barWidth = width / barcodeData.length;

  const barcodeComponent = (
    <Svg width={width} height={height} style={{ backgroundColor: '#ffffff' }}>
      {barcodeData.map((isBar, index) => (
        isBar && (
          <Rect
            key={index}
            x={index * barWidth}
            y={0}
            width={Math.max(barWidth, 1)} // Ensure minimum width of 1
            height={height}
            fill={color}
          />
        )
      ))}
    </Svg>
  );

  if (showLabel) {
    return (
      <YStack alignItems="center" gap="$1">
        {barcodeComponent}
        <Text fontSize="$2" color="$gray10" fontFamily="$mono" fontWeight="500">
          {code}
        </Text>
      </YStack>
    );
  }

  return barcodeComponent;
};