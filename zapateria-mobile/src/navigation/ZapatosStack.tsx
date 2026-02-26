import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import ZapatosScreen from "../screens/ZapatosScreen";
import ZapatoFormScreen from "../screens/ZapatoFormScreen";
import { Zapato } from "../types";

export type ZapatosStackParamList = {
  ZapatosList: undefined;
  ZapatoForm: { zapato?: Zapato } | undefined;
};

const Stack = createStackNavigator<ZapatosStackParamList>();

export default function ZapatosStack() {
  return (
    <Stack.Navigator>
      <Stack.Screen
        name="ZapatosList"
        component={ZapatosScreen}
        options={{
          title: "Zapatos",
          headerShown: false, // Ocultamos el header porque ya está en el Tab
        }}
      />
      <Stack.Screen
        name="ZapatoForm"
        component={ZapatoFormScreen}
        options={({ route }: any) => ({
          title: route.params?.zapato ? "Editar Zapato" : "Nuevo Zapato",
          headerBackTitle: "Volver",
        })}
      />
    </Stack.Navigator>
  );
}
