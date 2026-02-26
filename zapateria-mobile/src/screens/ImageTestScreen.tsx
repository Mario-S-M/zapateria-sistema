import React from "react";
import { ScrollView, Image } from "react-native";
import { YStack, XStack, Text, Card } from "tamagui";

export const ImageTestScreen = () => {
  const testImages = [
    'https://picsum.photos/200/200?random=1',
    'https://picsum.photos/200/200?random=2', 
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&h=200&fit=crop',
    'https://via.placeholder.com/200x200/ff0000/ffffff?text=TEST',
  ];

  return (
    <ScrollView style={{ flex: 1, padding: 20 }}>
      <YStack gap="$4">
        <Text fontSize="$6" fontWeight="bold">Test de Imágenes</Text>
        
        {testImages.map((uri, index) => (
          <Card key={index} padding="$3">
            <YStack gap="$2" alignItems="center">
              <Text fontSize="$4">Imagen {index + 1}</Text>
              <Text fontSize="$2" color="$gray10">{uri}</Text>
              <Image 
                source={{ uri }}
                style={{ 
                  width: 150, 
                  height: 150, 
                  borderRadius: 8,
                  backgroundColor: '#f3f4f6',
                  borderWidth: 1,
                  borderColor: '#e5e7eb',
                }}
                resizeMode="cover"
                onLoad={() => console.log('✅ Imagen cargada:', uri)}
                onError={(error) => console.log('❌ Error imagen:', uri, error.nativeEvent.error)}
              />
            </YStack>
          </Card>
        ))}
      </YStack>
    </ScrollView>
  );
};