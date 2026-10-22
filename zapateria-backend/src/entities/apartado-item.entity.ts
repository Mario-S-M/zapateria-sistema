import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Apartado } from './apartado.entity';
import { Zapato } from './zapato.entity';

const numeric = {
  to: (v?: number) => v,
  from: (v: string | null) => (v == null ? v : parseFloat(v)),
};

@Entity('apartado_items')
export class ApartadoItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  cantidad: number;

  @Column('decimal', { precision: 10, scale: 2, transformer: numeric })
  precioUnitario: number;

  @Column('decimal', { precision: 10, scale: 2, transformer: numeric })
  subtotal: number;

  @Column()
  apartadoId: string;

  @Column({ type: 'varchar', nullable: true })
  zapatoId: string | null;

  @Column({ type: 'varchar', nullable: true })
  inversionistaId: string | null;

  @Column({ type: 'varchar', nullable: true })
  colorId: string | null;

  @Column({
    type: 'decimal',
    precision: 5,
    scale: 1,
    nullable: true,
    transformer: numeric,
  })
  talla: number | null;

  @ManyToOne(() => Apartado, (apartado) => apartado.items, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'apartadoId' })
  apartado: Apartado;

  @ManyToOne(() => Zapato, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'zapatoId' })
  zapato: Zapato;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
