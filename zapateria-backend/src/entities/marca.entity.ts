import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { Zapato } from './zapato.entity';

export type BarcodeSegmentoTipo = 'fijo' | 'modelo' | 'lote' | 'talla';

export interface BarcodeSegmento {
  tipo: BarcodeSegmentoTipo;
  inicio: number;
  longitud: number;
}

@Entity('marcas')
@Index(['activo', 'patronLongitud'])
export class Marca {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100, unique: true })
  nombre: string;

  // Código de barras real pegado por el usuario al definir el patrón visualmente.
  // Se conserva para poder re-editar el layout de segmentos después.
  @Column({ nullable: true })
  codigoEjemplo?: string;

  // Layout ordenado de segmentos de ancho fijo que componen el código de barras
  // de esta marca (fijo | modelo | lote | talla). Nullable: una marca puede
  // existir sin patrón definido todavía.
  @Column({ type: 'simple-json', nullable: true })
  patronSegmentos: BarcodeSegmento[] | null;

  // Longitud total esperada del código de barras (suma de longitudes de segmentos),
  // desnormalizada para filtrar rápido por longitud al hacer matching en el escaneo.
  @Column({ nullable: true })
  patronLongitud?: number;

  @Column({ default: true })
  activo: boolean;

  @OneToMany(() => Zapato, (zapato) => zapato.marca)
  zapatos: Zapato[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
