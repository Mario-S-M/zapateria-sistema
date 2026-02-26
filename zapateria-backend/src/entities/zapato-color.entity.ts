import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Zapato } from './zapato.entity';
import { Color } from './color.entity';

@Entity('zapato_colores')
export class ZapatoColor {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  zapatoId: string;

  @Column()
  colorId: string;

  @ManyToOne(() => Zapato, (zapato) => zapato.colores, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'zapatoId' })
  zapato: Zapato;

  @ManyToOne(() => Color, (color) => color.zapatos, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'colorId' })
  color: Color;

  @CreateDateColumn()
  createdAt: Date;
}
