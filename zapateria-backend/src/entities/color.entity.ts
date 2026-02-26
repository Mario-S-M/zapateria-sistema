import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { ZapatoColor } from './zapato-color.entity';

@Entity('colores')
export class Color {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  nombre: string;

  @Column({ nullable: true })
  hexadecimal: string;

  @Column({ default: false })
  isCombo: boolean;

  @Column({ nullable: true })
  primaryColor: string;

  @Column({ nullable: true })
  secondaryColor: string;

  @OneToMany(() => ZapatoColor, (zapatoColor) => zapatoColor.color)
  zapatos: ZapatoColor[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
