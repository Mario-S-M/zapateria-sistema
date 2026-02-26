import React from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { TamaguiProvider, Theme } from "tamagui";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "sonner-native";
import { Ionicons } from "@expo/vector-icons";
import config from "./tamagui.config";
import { ThemeProvider, useTheme } from "./src/contexts/ThemeContext";
import ScannerScreen from "./src/screens/ScannerScreen";
import CartScreen from "./src/screens/CartScreen";
import VentasScreen from "./src/screens/VentasScreen";
import CierreCajaScreen from "./src/screens/CierreCajaScreen";
import ZapatosStack from "./src/navigation/ZapatosStack";

const Tab = createBottomTabNavigator();
const queryClient = new QueryClient();

// Componente interno que usa el tema
const AppContent = () => {
  const { actualTheme } = useTheme();

  return (
    <Theme name={actualTheme}>
      <NavigationContainer>
              <Tab.Navigator
                screenOptions={({ route }) => ({
                  headerShown: true,
                  tabBarActiveTintColor: actualTheme === 'dark' ? "#ffffff" : "#1f2937",
                  tabBarInactiveTintColor: actualTheme === 'dark' ? "#64748b" : "#6b7280",
                  tabBarStyle: {
                    backgroundColor: actualTheme === 'dark' ? "#1e293b" : "#ffffff",
                    borderTopColor: actualTheme === 'dark' ? "#475569" : "#e5e7eb",
                  },
                  headerStyle: {
                    backgroundColor: actualTheme === 'dark' ? "#0f172a" : "#ffffff",
                  },
                  headerTintColor: actualTheme === 'dark' ? "#f1f5f9" : "#1f2937",
                  tabBarIcon: ({ focused, color, size }) => {
                    let iconName: keyof typeof Ionicons.glyphMap;

                    if (route.name === "Scanner") {
                      iconName = focused ? "qr-code" : "qr-code-outline";
                    } else if (route.name === "Zapatos") {
                      iconName = focused ? "footsteps" : "footsteps-outline";
                    } else if (route.name === "Carrito") {
                      iconName = focused ? "cart" : "cart-outline";
                    } else if (route.name === "Ventas") {
                      iconName = focused ? "receipt" : "receipt-outline";
                    } else if (route.name === "CierreCaja") {
                      iconName = focused ? "cash" : "cash-outline";
                    } else {
                      iconName = "ellipse-outline";
                    }

                    return (
                      <Ionicons name={iconName} size={size} color={color} />
                    );
                  },
                })}
              >
                <Tab.Screen
                  name="Scanner"
                  component={ScannerScreen}
                  options={{
                    title: "Escáner",
                    tabBarLabel: "Escáner",
                  }}
                />
                <Tab.Screen
                  name="Zapatos"
                  component={ZapatosStack}
                  options={{
                    title: "Zapatos",
                    tabBarLabel: "Zapatos",
                  }}
                />
                <Tab.Screen
                  name="Carrito"
                  component={CartScreen}
                  options={{
                    title: "Carrito",
                    tabBarLabel: "Carrito",
                  }}
                />
                <Tab.Screen
                  name="Ventas"
                  component={VentasScreen}
                  options={{
                    title: "Ventas",
                    tabBarLabel: "Ventas",
                  }}
                />
                <Tab.Screen
                  name="CierreCaja"
                  component={CierreCajaScreen}
                  options={{
                    title: "Cierre de Caja",
                    tabBarLabel: "Cierre",
                  }}
                />
              </Tab.Navigator>
            </NavigationContainer>
            <Toaster />
      </Theme>
    );
};

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <TamaguiProvider config={config}>
          <ThemeProvider>
            <QueryClientProvider client={queryClient}>
              <AppContent />
            </QueryClientProvider>
          </ThemeProvider>
        </TamaguiProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
