import React from "react";
import { View } from "react-native";
import { Circle, XStack, YStack, Text } from "tamagui";
import Svg, {
  Defs,
  LinearGradient,
  Stop,
  Circle as SvgCircle,
} from "react-native-svg";
import { Color } from "../types";

interface ColorCircleProps {
  color: Color;
  size?: number;
  showName?: boolean;
}

export const ColorCircle: React.FC<ColorCircleProps> = ({
  color,
  size = 40,
  showName = false,
}) => {
  const renderSimpleColor = () => (
    <Circle
      size={size}
      backgroundColor={color.hexadecimal || "#CCCCCC"}
      borderWidth={1}
      borderColor="$gray8"
    />
  );

  const renderComboColor = () => {
    const primaryColor = color.primaryColor || "#FF0000";
    const secondaryColor = color.secondaryColor || "#000000";

    return (
      <View style={{ width: size, height: size }}>
        <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          <Defs>
            <LinearGradient id="split" x1="0%" y1="0%" x2="100%" y2="0%">
              <Stop offset="50%" stopColor={primaryColor} />
              <Stop offset="50%" stopColor={secondaryColor} />
            </LinearGradient>
          </Defs>
          <SvgCircle
            cx={size / 2}
            cy={size / 2}
            r={(size - 2) / 2}
            fill="url(#split)"
            stroke="#D1D5DB"
            strokeWidth={1}
          />
        </Svg>
      </View>
    );
  };

  if (showName) {
    return (
      <YStack alignItems="center" gap="$1">
        {color.isCombo ? renderComboColor() : renderSimpleColor()}
        <Text fontSize="$2" textAlign="center" maxWidth={60}>
          {color.nombre}
        </Text>
      </YStack>
    );
  }

  return color.isCombo ? renderComboColor() : renderSimpleColor();
};

interface ColorPickerProps {
  colors: Color[];
  selectedColorIds: string[];
  onColorSelect: (colorId: string) => void;
  maxSelections?: number;
}

export const ColorPicker: React.FC<ColorPickerProps> = ({
  colors,
  selectedColorIds,
  onColorSelect,
  maxSelections,
}) => {
  return (
    <XStack gap="$2" flexWrap="wrap" padding="$2">
      {colors.map((color) => {
        const isSelected = selectedColorIds.includes(color.id);
        const canSelect =
          !maxSelections ||
          selectedColorIds.length < maxSelections ||
          isSelected;

        return (
          <YStack key={color.id} alignItems="center" gap="$1">
            <View
              style={{
                opacity: canSelect ? 1 : 0.3,
                borderWidth: isSelected ? 3 : 1,
                borderColor: isSelected ? "#007AFF" : "#D1D5DB",
                borderRadius: 25,
                padding: 2,
              }}
              onTouchEnd={() => canSelect && onColorSelect(color.id)}
            >
              <ColorCircle color={color} size={40} />
            </View>
            <Text fontSize="$2" textAlign="center" maxWidth={60}>
              {color.nombre}
            </Text>
          </YStack>
        );
      })}
    </XStack>
  );
};
