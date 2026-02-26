/**
 * Genera un código de barras único
 * Usa timestamp + número aleatorio para garantizar unicidad
 */
export const generateBarcode = (): string => {
  const timestamp = Date.now().toString();
  const random = Math.floor(Math.random() * 10000)
    .toString()
    .padStart(4, "0");

  // Toma los últimos 8 dígitos del timestamp + 4 random = 12 dígitos
  return timestamp.slice(-8) + random;
};

/**
 * Valida que un código de barras tenga el formato correcto
 * @param barcode - Código de barras a validar
 * @returns true si es válido
 */
export const validateBarcode = (barcode: string): boolean => {
  // Debe ser un string de 12 dígitos
  return /^\d{12}$/.test(barcode);
};

/**
 * Formatea un código de barras para mostrar (agregar guiones)
 * @param barcode - Código de barras sin formato
 * @returns Código formateado (ej: 123456-789012)
 */
export const formatBarcode = (barcode: string): string => {
  if (barcode.length !== 12) return barcode;
  return barcode.slice(0, 6) + "-" + barcode.slice(6);
};
