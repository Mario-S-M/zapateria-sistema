import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Zapato } from './zapato.entity';
import { Color } from './color.entity';

@Entity('inventario')
export class Inventario {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  zapatoId: string;

  @Column({ nullable: true })
  colorId: string | undefined;

  @Column({
    type: 'decimal',
    precision: 5,
    scale: 1,
    transformer: { to: (v: number) => v, from: (v: string) => parseFloat(v) },
  })
  talla: number;

  @Column({ default: 0 })
  cantidad: number;

  @ManyToOne(() => Zapato, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'zapatoId' })
  zapato: Zapato;

  @ManyToOne(() => Color, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'colorId' })
  color: Color;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
