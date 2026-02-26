export interface Color {
  id: string;
  nombre: string;
  hexadecimal?: string;
  // Para combinaciones de colores
  isCombo?: boolean;
  primaryColor?: string; // Hex del color principal
  secondaryColor?: string; // Hex del color secundario
  createdAt: string;
  updatedAt: string;
}

export interface ZapatoColor {
  id: string;
  zapatoId: string;
  colorId: string;
  color: Color;
  createdAt: string;
}

export interface Categoria {
  id: string;
  nombre: string;
  activo: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Zapato {
  id: string;
  codigoBarras: string;
  nombre: string;
  modelo: string;
  foto?: string; // Opcional temporalmente para datos existentes
  precioCompra: number;
  precioPublico: number;
  medidaInicio: number;
  medidaFin: number;
  categoriaId?: string;
  categoria?: Categoria;
  inversionistaId?: string;
  inversionista?: Inversionista;
  colores: ZapatoColor[];
  createdAt: string;
  updatedAt: string;
}

export interface Inversionista {
  id: string;
  nombre: string;
  telefono?: string;
  email?: string;
  activo: boolean;
  createdAt: string;
  updatedAt: string;
}

export enum TipoPrecio {
  PUBLICO = "PUBLICO",
  MAYORISTA = "MAYORISTA",
  INVERSIONISTA = "INVERSIONISTA",
}

export interface VentaItem {
  id: string;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
  ventaId: string;
  zapatoId: string | null;
  zapato: Zapato | null;
  createdAt: string;
  updatedAt: string;
}

export interface Venta {
  id: string;
  folio: string;
  fecha: string;
  total: number;
  tipoPrecio: TipoPrecio;
  inversionistaId?: string;
  inversionista?: Inversionista;
  items: VentaItem[];
  createdAt: string;
  updatedAt: string;
}
