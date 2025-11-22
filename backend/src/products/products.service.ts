import { Injectable } from '@nestjs/common';
import { Product } from './interfaces/product.interface';

@Injectable({})
export class ProductsService {
  private products: Product[] = [];

  findAll(): Product[] {
    return this.products;
  }

  create(product: Product): Product {
    this.products.push(product);

    return this.products[this.products.length - 1];
  }
}
