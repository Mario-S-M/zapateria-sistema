import React, { useState } from 'react';
import { YStack, XStack, Text, Button } from 'tamagui';
import { MaterialIcons } from '@expo/vector-icons';

interface SimpleCalendarProps {
  onDateSelect: (date: Date) => void;
  isDark: boolean;
}

export default function SimpleCalendar({ onDateSelect, isDark }: SimpleCalendarProps) {
  const [currentDate, setCurrentDate] = useState(new Date());

  const getDaysInMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
  };

  const daysInMonth = getDaysInMonth(currentDate);
  const firstDay = getFirstDayOfMonth(currentDate);
  const days = [];

  // Llenar con días en blanco del mes anterior
  for (let i = 0; i < firstDay; i++) {
    days.push(null);
  }

  // Llenar con los días del mes
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(i);
  }

  const previousMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1));
  };

  const selectDay = (day: number) => {
    const selectedDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), day);
    onDateSelect(selectedDate);
  };

  const monthYear = currentDate.toLocaleDateString('es-MX', {
    month: 'long',
    year: 'numeric',
  });

  const weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  return (
    <YStack gap="$3" padding="$4" backgroundColor={isDark ? '#1a1a1a' : '#f9f9f9'} borderRadius="$4">
      {/* Header */}
      <XStack justifyContent="space-between" alignItems="center" marginBottom="$2">
        <Button size="$2" onPress={previousMonth} backgroundColor={isDark ? '#333' : '#e0e0e0'}>
          <MaterialIcons name="chevron-left" size={20} color={isDark ? '#fff' : '#000'} />
        </Button>

        <Text fontSize="$5" fontWeight="bold" color={isDark ? '#fff' : '#000'} textTransform="capitalize">
          {monthYear}
        </Text>

        <Button size="$2" onPress={nextMonth} backgroundColor={isDark ? '#333' : '#e0e0e0'}>
          <MaterialIcons name="chevron-right" size={20} color={isDark ? '#fff' : '#000'} />
        </Button>
      </XStack>

      {/* Días de la semana */}
      <YStack>
        <XStack>
          {weekDays.map((day) => (
            <YStack key={day} flex={1} alignItems="center" paddingVertical="$2">
              <Text fontSize="$2" fontWeight="600" color={isDark ? '#aaa' : '#666'}>
                {day}
              </Text>
            </YStack>
          ))}
        </XStack>

        {/* Grid de días */}
        {Array.from({ length: Math.ceil(days.length / 7) }).map((_, weekIndex) => (
          <XStack key={weekIndex} marginTop="$1">
            {days.slice(weekIndex * 7, (weekIndex + 1) * 7).map((day, dayIndex) => (
              <YStack key={dayIndex} flex={1} alignItems="center" paddingVertical="$2">
                {day ? (
                  <Button
                    onPress={() => selectDay(day)}
                    backgroundColor="$blue10"
                    borderRadius="$2"
                    padding="$2"
                    minWidth="$7"
                    minHeight="$7"
                    justifyContent="center"
                    alignItems="center"
                  >
                    <Text color="#fff" fontWeight="600" fontSize="$3">
                      {day}
                    </Text>
                  </Button>
                ) : (
                  <YStack minWidth="$7" minHeight="$7" />
                )}
              </YStack>
            ))}
          </XStack>
        ))}
      </YStack>
    </YStack>
  );
}
