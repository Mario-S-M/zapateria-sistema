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
import { ApartadoItem } from './apartado-item.entity';
import { Abono } from './abono.entity';
import { TipoPrecio } from './venta.entity';

export enum EstadoApartado {
  ACTIVO = 'ACTIVO',
  ENTREGADO = 'ENTREGADO',
  CANCELADO = 'CANCELADO',
}

const numeric = {
  to: (v?: number) => v,
  from: (v: string | null) => (v == null ? v : parseFloat(v)),
};

@Entity('apartados')
export class Apartado {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  folio: string;

  @Column()
  clienteNombre: string;

  @Column({ type: 'varchar', nullable: true })
  clienteTelefono: string | null;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  fecha: Date;

  @Column('decimal', { precision: 10, scale: 2, transformer: numeric })
  total: number;

  @Column({ type: 'enum', enum: TipoPrecio, default: TipoPrecio.PUBLICO })
  tipoPrecio: TipoPrecio;

  @Column({
    type: 'enum',
    enum: EstadoApartado,
    default: EstadoApartado.ACTIVO,
  })
  estado: EstadoApartado;

  @Column({ type: 'varchar', nullable: true })
  inversionistaId: string | null;

  @ManyToOne(() => Inversionista, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'inversionistaId' })
  inversionista: Inversionista;

  @Column({ type: 'varchar', nullable: true })
  ventaId: string | null;

  @OneToMany(() => ApartadoItem, (item) => item.apartado, { cascade: true })
  items: ApartadoItem[];

  @OneToMany(() => Abono, (abono) => abono.apartado, { cascade: true })
  abonos: Abono[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
