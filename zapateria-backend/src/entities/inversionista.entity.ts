import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Venta } from './venta.entity';
import { Zapato } from './zapato.entity';

@Entity('inversionistas')
export class Inversionista {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  nombre: string;

  @Column({ nullable: true })
  telefono: string;

  @Column({ nullable: true })
  email: string;

  @Column({ default: true })
  activo: boolean;

  @OneToMany(() => Venta, (venta) => venta.inversionista)
  ventas: Venta[];

  @OneToMany(() => Zapato, (zapato) => zapato.inversionista)
  zapatos: Zapato[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
