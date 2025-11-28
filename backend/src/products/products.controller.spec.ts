import { Test, TestingModule } from '@nestjs/testing';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';
import {
  generateMockCreateProductDto,
  generateMockProduct,
  generateMockUpdateProductDto,
} from './products.test-helper';

describe('ProductsController', () => {
  let controller: ProductsController;
  let productsService: ProductsService;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [ProductsController],
      providers: [
        {
          provide: ProductsService,
          useValue: {
            findAll: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = app.get<ProductsController>(ProductsController);
    productsService = app.get<ProductsService>(ProductsService);
  });

  describe('findAll', () => {
    it('query via productService', async () => {
      const mockProducts = [generateMockProduct()];

      jest.spyOn(productsService, 'findAll').mockResolvedValue(mockProducts);

      const result = await controller.findAll();

      expect(productsService.findAll).toHaveBeenCalled();
      expect(result).toStrictEqual(mockProducts);
    });

    it('should propagate service errors', async () => {
      jest
        .spyOn(productsService, 'findAll')
        .mockRejectedValue(new Error('Error From Service'));

      const calls = async () => {
        await controller.findAll();
      };

      await expect(calls()).rejects.toThrow('Error From Service');
    });
  });

  describe('findOne', () => {
    it('query via productService', async () => {
      const mockProduct = generateMockProduct();

      jest.spyOn(productsService, 'findOne').mockResolvedValue(mockProduct);

      const result = await controller.findOne(mockProduct.id);

      expect(productsService.findOne).toHaveBeenCalledWith(mockProduct.id);
      expect(result).toStrictEqual(mockProduct);
    });

    it('should propagate service errors', async () => {
      jest
        .spyOn(productsService, 'findOne')
        .mockRejectedValue(new Error('Error From Service'));

      const calls = async () => {
        await controller.findOne(999);
      };

      await expect(calls()).rejects.toThrow('Error From Service');
    });
  });

  describe('create', () => {
    it('query via productService', async () => {
      const mockProduct = generateMockProduct();
      const mockCreateProductDto = generateMockCreateProductDto();

      jest.spyOn(productsService, 'create').mockResolvedValue(mockProduct);

      const result = await controller.create(mockCreateProductDto);

      expect(productsService.create).toHaveBeenCalledWith(mockCreateProductDto);
      expect(result).toStrictEqual(mockProduct);
    });

    it('should propagate service errors', async () => {
      jest
        .spyOn(productsService, 'create')
        .mockRejectedValue(new Error('Error From Service'));

      const calls = async () => {
        await controller.create({
          name: 'invalid',
          description: 'invalid',
          price: 0,
        });
      };

      await expect(calls()).rejects.toThrow('Error From Service');
    });
  });

  describe('update', () => {
    it('query via productService', async () => {
      const mockProduct = generateMockProduct();
      const mockUpdateProductDto = generateMockUpdateProductDto();

      jest
        .spyOn(productsService, 'update')
        .mockResolvedValue({ ...mockProduct, ...mockUpdateProductDto });

      const result = await controller.update(
        mockProduct.id,
        mockUpdateProductDto,
      );

      expect(productsService.update).toHaveBeenCalledWith(
        mockProduct.id,
        mockUpdateProductDto,
      );
      expect(result).toStrictEqual({ ...mockProduct, ...mockUpdateProductDto });
    });

    it('should propagate service errors', async () => {
      jest
        .spyOn(productsService, 'update')
        .mockRejectedValue(new Error('Error From Service'));

      const calls = async () => {
        await controller.update(999, {});
      };

      await expect(calls()).rejects.toThrow('Error From Service');
    });
  });

  describe('delete', () => {
    it('query via productService', async () => {
      const mockProduct = generateMockProduct();

      jest.spyOn(productsService, 'delete').mockResolvedValue({});

      const result = await controller.delete(mockProduct.id);

      expect(productsService.delete).toHaveBeenCalledWith(mockProduct.id);
      expect(result).toStrictEqual({});
    });

    it('should propagate service errors', async () => {
      jest
        .spyOn(productsService, 'delete')
        .mockRejectedValue(new Error('Error From Service'));

      const calls = async () => {
        await controller.delete(999);
      };

      await expect(calls()).rejects.toThrow('Error From Service');
    });
  });
});
