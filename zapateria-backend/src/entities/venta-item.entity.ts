import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Venta } from './venta.entity';
import { Zapato } from './zapato.entity';
import { Inversionista } from './inversionista.entity';

@Entity('venta_items')
export class VentaItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  cantidad: number;

  @Column('decimal', { precision: 10, scale: 2 })
  precioUnitario: number;

  @Column('decimal', { precision: 10, scale: 2 })
  subtotal: number;

  @Column()
  ventaId: string;

  @Column({ nullable: true })
  zapatoId: string;

  @Column({ nullable: true })
  inversionistaId: string;

  @ManyToOne(() => Venta, (venta) => venta.items, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'ventaId' })
  venta: Venta;

  @ManyToOne(() => Zapato, (zapato) => zapato.ventaItems, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'zapatoId' })
  zapato: Zapato;

  @ManyToOne(() => Inversionista, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'inversionistaId' })
  inversionista: Inversionista;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
