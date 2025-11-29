import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { Product } from 'generated/prisma/client';
import { CreateProductDto, UpdateProductDto } from './dto';
import { PrismaErrorHandler } from 'src/prisma/prisma-error-handler';

@Injectable({})
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async findAll(): Promise<Product[]> {
    const products = this.prisma.product.findMany({
      select: {
        id: true,
        name: true,
        description: true,
        price: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return products;
  }

  async findOne(id: number): Promise<Product> {
    try {
      const product = await this.prisma.product.findFirstOrThrow({
        where: { id: id },
      });

      return product;
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException('Not found', HttpStatus.NOT_FOUND);
      }
      throw error;
    }
  }

  async create(productDto: CreateProductDto): Promise<Product> {
    try {
      const product = await this.prisma.product.create({ data: productDto });

      return product;
    } catch (error) {
      PrismaErrorHandler.handle(error, 'Product');
    }
  }

  async update(id: number, productDto: UpdateProductDto): Promise<Product> {
    try {
      return await this.prisma.product.update({
        where: {
          id: id,
        },
        data: { ...productDto },
      });
    } catch (error) {
      PrismaErrorHandler.handle(error, 'Product');
    }
  }

  async delete(id: number): Promise<{}> {
    try {
      return (
        (await this.prisma.product.delete({
          where: {
            id: id,
          },
        })) && {}
      );
    } catch (error) {
      PrismaErrorHandler.handle(error, 'Product');
    }
  }
}
