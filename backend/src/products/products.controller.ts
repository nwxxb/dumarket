import { Body, Controller, Get, Post } from '@nestjs/common';
import { ProductsService } from './products.service';
import type { Product } from './interfaces/product.interface';

@Controller('products')
export class ProductsController {
  constructor(private productsService: ProductsService) {}
  @Get()
  findAll(): Product[] {
    return this.productsService.findAll();
  }

  @Post()
  create(@Body() product: Product): Product {
    return this.productsService.create(product);
  }
}
