import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { Inversionista } from './inversionista.entity';
import { VentaItem } from './venta-item.entity';

export enum TipoPrecio {
  PUBLICO = 'PUBLICO',
  MAYORISTA = 'MAYORISTA',
  INVERSIONISTA = 'INVERSIONISTA',
}

@Entity('ventas')
export class Venta {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  folio: string;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  fecha: Date;

  @Column('decimal', { precision: 10, scale: 2 })
  total: number;

  @Column({
    type: 'enum',
    enum: TipoPrecio,
    default: TipoPrecio.PUBLICO,
  })
  tipoPrecio: TipoPrecio;

  @Column({ nullable: true })
  inversionistaId: string;

  @ManyToOne(() => Inversionista, (inversionista) => inversionista.ventas, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'inversionistaId' })
  inversionista: Inversionista;

  @OneToMany(() => VentaItem, (ventaItem) => ventaItem.venta, {
    cascade: true,
  })
  items: VentaItem[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
