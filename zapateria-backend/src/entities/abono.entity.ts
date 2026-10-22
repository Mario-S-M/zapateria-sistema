import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Apartado } from './apartado.entity';

export enum MetodoAbono {
  EFECTIVO = 'EFECTIVO',
  TARJETA = 'TARJETA',
}

@Entity('abonos')
export class Abono {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  apartadoId: string;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    transformer: {
      to: (v?: number) => v,
      from: (v: string | null) => (v == null ? v : parseFloat(v)),
    },
  })
  monto: number;

  @Column({ type: 'enum', enum: MetodoAbono })
  metodoPago: MetodoAbono;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  fecha: Date;

  @ManyToOne(() => Apartado, (apartado) => apartado.abonos, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'apartadoId' })
  apartado: Apartado;

  @CreateDateColumn()
  createdAt: Date;
}
