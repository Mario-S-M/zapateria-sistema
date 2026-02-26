/**
 * Formatea un precio de manera segura, convirtiendo strings y manejando valores nulos/undefined
 * @param price - El precio que puede ser number, string, null o undefined
 * @returns El precio formateado como string con 2 decimales
 */
export const formatPrice = (
  price: number | string | null | undefined
): string => {
  if (price === null || price === undefined || price === "") {
    return "0.00";
  }

  const numPrice = typeof price === "string" ? parseFloat(price) : price;

  if (isNaN(numPrice)) {
    return "0.00";
  }

  return numPrice.toFixed(2);
};

/**
 * Convierte un precio a número de manera segura
 * @param price - El precio que puede ser number, string, null o undefined
 * @returns El precio como número
 */
export const parsePrice = (
  price: number | string | null | undefined
): number => {
  if (price === null || price === undefined || price === "") {
    return 0;
  }

  const numPrice = typeof price === "string" ? parseFloat(price) : price;

  if (isNaN(numPrice)) {
    return 0;
  }

  return numPrice;
};
