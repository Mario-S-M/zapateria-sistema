import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Zapato } from './zapato.entity';

@Entity('categorias')
export class Categoria {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100, unique: true })
  nombre: string;

  @Column({ default: true })
  activo: boolean;

  @OneToMany(() => Zapato, zapato => zapato.categoria)
  zapatos: Zapato[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}