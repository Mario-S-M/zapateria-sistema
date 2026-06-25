import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Zapato } from './zapato.entity';

@Entity('precio_rangos')
export class PrecioRango {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  zapatoId: string;

  @Column('decimal', {
    precision: 4,
    scale: 1,
    transformer: { to: (v: number) => v, from: (v: string) => parseFloat(v) },
  })
  medidaInicio: number;

  @Column('decimal', {
    precision: 4,
    scale: 1,
    transformer: { to: (v: number) => v, from: (v: string) => parseFloat(v) },
  })
  medidaFin: number;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    transformer: { to: (v: number) => v, from: (v: string) => parseFloat(v) },
  })
  precioCompra: number;

  @Column('decimal', {
    precision: 10,
    scale: 2,
    transformer: { to: (v: number) => v, from: (v: string) => parseFloat(v) },
  })
  precioPublico: number;

  @ManyToOne(() => Zapato, (zapato) => zapato.precioRangos, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'zapatoId' })
  zapato: Zapato;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
