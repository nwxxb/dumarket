import { Product } from 'generated/prisma/browser';
import { CreateProductDto, UpdateProductDto } from './dto';

let productIdCounter = 0;

beforeEach(() => {
  productIdCounter = 0;
});

export const generateMockProduct = (overrides?: Partial<Product>): Product => {
  return {
    id: ++productIdCounter,
    name: `Test Product ${productIdCounter}`,
    price: 99.99,
    description: `Test description for product ${productIdCounter}`,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
};

export const generateMockCreateProductDto = (
  overrides?: Partial<CreateProductDto>,
): CreateProductDto => {
  return {
    name: `Test Product ${productIdCounter}`,
    price: 99.99,
    description: `Test description ${productIdCounter}`,
    ...overrides,
  };
};

export const generateMockUpdateProductDto = (
  overrides?: Partial<UpdateProductDto>,
): UpdateProductDto => {
  return {
    name: `Test Product ${productIdCounter}`,
    price: 99.99,
    description: `Test description ${productIdCounter}`,
    ...overrides,
  };
};
