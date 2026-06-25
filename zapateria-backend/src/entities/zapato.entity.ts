import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ZapatoColor } from './zapato-color.entity';
import { VentaItem } from './venta-item.entity';
import { Categoria } from './categoria.entity';
import { Inversionista } from './inversionista.entity';
import { PrecioRango } from './precio-rango.entity';

export enum Horma {
  NORMAL = 'NORMAL',
  REDUCIDO = 'REDUCIDO',
  AMPLIO = 'AMPLIO',
}

@Entity('zapatos')
export class Zapato {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  codigoBarras: string;

  @Column()
  nombre: string;

  @Column()
  modelo: string;

  @Column()
  foto: string;

  @Column({ type: 'simple-json', nullable: true })
  fotos: string[] | null;

  @Column('decimal', { precision: 10, scale: 2 })
  precioCompra: number;

  @Column('decimal', { precision: 10, scale: 2 })
  precioPublico: number;

  @Column('decimal', { precision: 4, scale: 1 })
  medidaInicio: number;

  @Column('decimal', { precision: 4, scale: 1 })
  medidaFin: number;

  @Column({ type: 'enum', enum: Horma, default: Horma.NORMAL })
  horma: Horma;

  @Column({ nullable: true })
  categoriaId?: string;

  @ManyToOne(() => Categoria, categoria => categoria.zapatos)
  @JoinColumn({ name: 'categoriaId' })
  categoria?: Categoria;

  @Column({ nullable: true })
  inversionistaId?: string;

  @ManyToOne(() => Inversionista, inversionista => inversionista.zapatos)
  @JoinColumn({ name: 'inversionistaId' })
  inversionista?: Inversionista;

  @OneToMany(() => ZapatoColor, (zapatoColor) => zapatoColor.zapato)
  colores: ZapatoColor[];

  @OneToMany(() => VentaItem, (ventaItem) => ventaItem.zapato)
  ventaItems: VentaItem[];

  @OneToMany(() => PrecioRango, (pr) => pr.zapato)
  precioRangos: PrecioRango[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
