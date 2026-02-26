import React, { useEffect, useState } from 'react';
import { ScrollView, RefreshControl, Alert, Modal } from 'react-native';
import { YStack, XStack, Text, Card, Spinner, Button } from 'tamagui';
import { MaterialIcons } from '@expo/vector-icons';
import { cierreCajaService, CierreCajaDia } from '../services/cierre-caja.service';
import { useTheme } from '../contexts/ThemeContext';
import SimpleCalendar from '../components/SimpleCalendar';

export default function CierreCajaScreen() {
  const { isDark } = useTheme();
  const [reportes, setReportes] = useState<CierreCajaDia[]>([]);
  const [diaSeleccionado, setDiaSeleccionado] = useState<CierreCajaDia | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [fechaSeleccionada, setFechaSeleccionada] = useState<Date>(new Date());

  const cargarReportes = async (fecha?: Date) => {
    try {
      setLoading(true);
      
      // Cargar todos los reportes primero
      const data = await cierreCajaService.getReporte();
      console.log('📊 Todos los reportes:', data);
      setReportes(data);
      
      // Si se proporciona una fecha, buscar ese día
      if (fecha) {
        // Usar la fecha local sin considerar la zona horaria
        const year = fecha.getFullYear();
        const month = String(fecha.getMonth() + 1).padStart(2, '0');
        const day = String(fecha.getDate()).padStart(2, '0');
        const fechaFormato = `${year}-${month}-${day}`;
        
        console.log(`🔍 Buscando fecha: ${fechaFormato}`);
        const diaEncontrado = data.find(d => {
          console.log(`  Comparando: "${d.fecha}" === "${fechaFormato}" ? ${d.fecha === fechaFormato}`);
          return d.fecha === fechaFormato;
        });
        
        if (diaEncontrado) {
          console.log('✅ Día encontrado:', diaEncontrado);
          setDiaSeleccionado(diaEncontrado);
          setFechaSeleccionada(fecha);
        } else {
          console.log('❌ No se encontró el día en los reportes');
          Alert.alert('Sin datos', 'No hay ventas registradas para esta fecha');
          setDiaSeleccionado(null);
        }
      }
    } catch (error: any) {
      console.error('Error al cargar reportes:', error);
      Alert.alert('Error', error.response?.data?.message || 'Error al cargar reportes');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    cargarReportes();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    cargarReportes();
  };

  const handleDateChange = (selectedDate: Date) => {
    cargarReportes(selectedDate);
    setShowDatePicker(false);
  };

  const limpiarSeleccion = () => {
    setDiaSeleccionado(null);
  };

  const formatearFecha = (fechaISO: string) => {
    const fecha = new Date(fechaISO);
    return fecha.toLocaleDateString('es-MX', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  };

  const formatearDinero = (cantidad: number) => {
    return new Intl.NumberFormat('es-MX', {
      style: 'currency',
      currency: 'MXN',
    }).format(cantidad);
  };

  if (loading && !refreshing) {
    return (
      <YStack flex={1} justifyContent="center" alignItems="center" backgroundColor={isDark ? '#000' : '#fff'}>
        <Spinner size="large" color="$blue10" />
        <Text mt="$4" color={isDark ? '#fff' : '#000'}>Cargando reportes...</Text>
      </YStack>
    );
  }

  return (
    <YStack flex={1} backgroundColor={isDark ? '#000' : '#fff'}>
      {/* Header */}
      <YStack padding="$4" borderBottomWidth={1} borderColor={isDark ? '#333' : '#ddd'}>
        <Text fontSize="$6" fontWeight="bold" color={isDark ? '#fff' : '#000'} mb="$3">
          Cierre de Caja
        </Text>
        
        {diaSeleccionado ? (
          // Vista de día seleccionado
          <YStack>
            <XStack justifyContent="space-between" alignItems="center" gap="$2">
              <YStack flex={1}>
                <Text fontSize="$3" color={isDark ? '#aaa' : '#666'} mb="$1">
                  Fecha seleccionada:
                </Text>
                <Text fontSize="$5" fontWeight="bold" color={isDark ? '#fff' : '#000'} textTransform="capitalize">
                  {formatearFecha(diaSeleccionado.fecha)}
                </Text>
              </YStack>
              <Button onPress={() => setShowDatePicker(true)} backgroundColor="$blue10" size="$3">
                <MaterialIcons name="calendar-today" size={18} color="#fff" />
              </Button>
            </XStack>

            <Button mt="$3" onPress={limpiarSeleccion} backgroundColor={isDark ? '#333' : '#e0e0e0'}>
              <MaterialIcons name="clear" size={18} color={isDark ? '#fff' : '#000'} />
              <Text color={isDark ? '#fff' : '#000'} ml="$2">Limpiar selección</Text>
            </Button>
          </YStack>
        ) : (
          // Vista de seleccionar fecha
          <Button onPress={() => setShowDatePicker(true)} backgroundColor="$blue10">
            <MaterialIcons name="calendar-today" size={20} color="#fff" />
            <Text color="#fff" ml="$2">Seleccionar un día</Text>
          </Button>
        )}
      </YStack>

      {/* Date Picker Modal */}
      <Modal
        visible={showDatePicker}
        transparent={true}
        animationType="slide"
        onRequestClose={() => setShowDatePicker(false)}
      >
        <YStack flex={1} justifyContent="flex-end" backgroundColor="rgba(0,0,0,0.5)">
          <YStack backgroundColor={isDark ? '#0a0a0a' : '#fff'} paddingBottom="$5" maxHeight="80%">
            <XStack padding="$4" justifyContent="space-between" alignItems="center" borderBottomWidth={1} borderColor={isDark ? '#333' : '#ddd'}>
              <Text fontSize="$5" fontWeight="bold" color={isDark ? '#fff' : '#000'}>
                Seleccionar fecha
              </Text>
              <Button size="$2" onPress={() => setShowDatePicker(false)} backgroundColor={isDark ? '#333' : '#e0e0e0'}>
                <MaterialIcons name="close" size={18} color={isDark ? '#fff' : '#000'} />
              </Button>
            </XStack>
            
            <ScrollView>
              <YStack padding="$4">
                <SimpleCalendar
                  onDateSelect={(date) => {
                    handleDateChange(date);
                  }}
                  isDark={isDark}
                />
              </YStack>
            </ScrollView>
          </YStack>
        </YStack>
      </Modal>

      {/* Contenido */}
      <ScrollView
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        <YStack padding="$4">
          {diaSeleccionado ? (
            // Mostrar datos del día seleccionado
            <Card
              padding="$4"
              backgroundColor={isDark ? '#1a1a1a' : '#f9f9f9'}
              borderColor={isDark ? '#333' : '#e0e0e0'}
              borderWidth={1}
              elevate
            >
              {/* Encabezado del día */}
              <YStack mb="$4" pb="$3" borderBottomWidth={1} borderColor={isDark ? '#333' : '#e0e0e0'}>
                <Text fontSize="$2" color={isDark ? '#888' : '#666'} mb="$2">Total del día</Text>
                <Text fontSize="$7" fontWeight="bold" color="$green10">
                  {formatearDinero(diaSeleccionado.totalDia)}
                </Text>
              </YStack>

              {/* Lista de inversionistas */}
              <YStack gap="$3">
                <Text fontSize="$4" fontWeight="bold" color={isDark ? '#fff' : '#000'} mb="$2">
                  Desglose por inversionista
                </Text>
                {diaSeleccionado.inversionistas.map((inv) => (
                  <Card
                    key={inv.inversionistaId}
                    padding="$4"
                    backgroundColor={isDark ? '#0a0a0a' : '#fff'}
                    borderColor={isDark ? '#222' : '#f0f0f0'}
                    borderWidth={1}
                  >
                    <XStack justifyContent="space-between" alignItems="center" mb="$2">
                      <YStack flex={1}>
                        <Text fontSize="$5" fontWeight="600" color={isDark ? '#fff' : '#000'}>
                          {inv.nombre}
                        </Text>
                        <Text fontSize="$3" color={isDark ? '#888' : '#666'} mt="$1">
                          {inv.totalItems} {inv.totalItems === 1 ? 'artículo' : 'artículos'}
                        </Text>
                      </YStack>
                      <Text fontSize="$6" fontWeight="bold" color={isDark ? '#4ade80' : '#16a34a'}>
                        {formatearDinero(inv.total)}
                      </Text>
                    </XStack>
                  </Card>
                ))}
              </YStack>
            </Card>
          ) : (
            // Sin selección
            <YStack alignItems="center" padding="$6">
              <MaterialIcons name="calendar-month" size={64} color={isDark ? '#444' : '#ccc'} />
              <Text mt="$4" color={isDark ? '#888' : '#666'} textAlign="center" fontSize="$4">
                Selecciona un día para ver el reporte
              </Text>
            </YStack>
          )}
        </YStack>
      </ScrollView>
    </YStack>
  );
}
