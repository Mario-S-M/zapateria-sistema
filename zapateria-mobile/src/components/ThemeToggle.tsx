import React from 'react';
import { Button, XStack, Text } from 'tamagui';
import { useTheme } from '../contexts/ThemeContext';

interface ThemeToggleProps {
  showLabel?: boolean;
  size?: '$2' | '$3' | '$4';
}

export const ThemeToggle: React.FC<ThemeToggleProps> = ({ 
  showLabel = true, 
  size = '$3' 
}) => {
  const { themeMode, actualTheme, setThemeMode, toggleTheme } = useTheme();

  const getThemeIcon = () => {
    if (themeMode === 'system') {
      return 'Auto';
    }
    return actualTheme === 'light' ? 'Claro' : 'Oscuro';
  };

  const getThemeLabel = () => {
    switch (themeMode) {
      case 'light': return 'Claro';
      case 'dark': return 'Oscuro';
      case 'system': return 'Sistema';
      default: return 'Claro';
    }
  };

  const cycleTheme = () => {
    switch (themeMode) {
      case 'light':
        setThemeMode('dark');
        break;
      case 'dark':
        setThemeMode('system');
        break;
      case 'system':
        setThemeMode('light');
        break;
    }
  };

  return (
    <XStack gap="$2" alignItems="center">
      {showLabel && (
        <Text fontSize="$3" fontWeight="500">
          Tema:
        </Text>
      )}
      <Button
        size={size}
        backgroundColor="$gray8"
        color="$gray12"
        borderColor="$gray8"
        onPress={cycleTheme}
        pressStyle={{ backgroundColor: "$gray9" }}
        hoverStyle={{ backgroundColor: "$gray9" }}
      >
        {showLabel ? (
          <XStack gap="$2" alignItems="center">
            <Text fontSize="$3" fontWeight="500">
              {getThemeLabel()}
            </Text>
          </XStack>
        ) : (
          <Text fontSize="$2" fontWeight="500">
            {getThemeIcon()}
          </Text>
        )}
      </Button>
    </XStack>
  );
};