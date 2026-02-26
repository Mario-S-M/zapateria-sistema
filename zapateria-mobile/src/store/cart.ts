import { create } from "zustand";
import { Zapato, TipoPrecio } from "../types";
import { parsePrice } from "../utils/priceUtils";

interface CartItem {
  zapato: Zapato;
  cantidad: number;
  precioUnitario: number;
}

interface CartStore {
  items: CartItem[];
  tipoPrecio: TipoPrecio;
  inversionistaId?: string;
  addItem: (zapato: Zapato, cantidad: number, precioUnitario: number) => void;
  removeItem: (zapatoId: string) => void;
  updateQuantity: (zapatoId: string, cantidad: number) => void;
  clearCart: () => void;
  setTipoPrecio: (tipo: TipoPrecio) => void;
  setInversionista: (id: string | undefined) => void;
  getTotal: () => number;
}

export const useCartStore = create<CartStore>((set, get) => ({
  items: [],
  tipoPrecio: TipoPrecio.PUBLICO,
  inversionistaId: undefined,

  addItem: (zapato, cantidad, precioUnitario) => {
    const items = get().items;
    const existingItem = items.find((item) => item.zapato.id === zapato.id);

    if (existingItem) {
      set({
        items: items.map((item) =>
          item.zapato.id === zapato.id
            ? { ...item, cantidad: item.cantidad + cantidad }
            : item
        ),
      });
    } else {
      set({ items: [...items, { zapato, cantidad, precioUnitario }] });
    }
  },

  removeItem: (zapatoId) => {
    set({ items: get().items.filter((item) => item.zapato.id !== zapatoId) });
  },

  updateQuantity: (zapatoId, cantidad) => {
    set({
      items: get().items.map((item) =>
        item.zapato.id === zapatoId ? { ...item, cantidad } : item
      ),
    });
  },

  clearCart: () => {
    set({ items: [], inversionistaId: undefined });
  },

  setTipoPrecio: (tipo) => {
    set({ tipoPrecio: tipo });
  },

  setInversionista: (id) => {
    set({ inversionistaId: id });
  },

  getTotal: () => {
    return get().items.reduce(
      (total, item) => total + parsePrice(item.precioUnitario) * item.cantidad,
      0
    );
  },
}));
