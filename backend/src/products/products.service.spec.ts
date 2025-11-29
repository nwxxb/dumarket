import { Test, TestingModule } from '@nestjs/testing';
import { ProductsService } from './products.service';
import {
  generateMockCreateProductDto,
  generateMockProduct,
  generateMockUpdateProductDto,
} from './products.test-helper';
import { PrismaService } from 'src/prisma/prisma.service';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClientKnownRequestError } from 'generated/prisma/internal/prismaNamespace';
import { HttpException, HttpStatus } from '@nestjs/common';

describe('ProductsController', () => {
  let service: ProductsService;
  let prismaService: DeepMockProxy<PrismaService>;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      providers: [
        ProductsService,
        {
          provide: PrismaService,
          useValue: mockDeep<PrismaService>(),
        },
      ],
    }).compile();

    service = app.get<ProductsService>(ProductsService);
    prismaService = app.get<DeepMockProxy<PrismaService>>(PrismaService);
  });

  describe('findAll', () => {
    it('query multiple products', async () => {
      const mockProducts = [generateMockProduct(), generateMockProduct()];

      jest
        .spyOn(prismaService.product, 'findMany')
        .mockResolvedValue(mockProducts);

      const result = await service.findAll();

      expect(prismaService.product.findMany).toHaveBeenCalled();
      expect(result).toStrictEqual(mockProducts);
    });
  });

  describe('findOne', () => {
    it('should return correct product', async () => {
      const mockProduct = generateMockProduct();

      jest
        .spyOn(prismaService.product, 'findFirstOrThrow')
        .mockResolvedValue(mockProduct);

      const result = await service.findOne(mockProduct.id);

      expect(prismaService.product.findFirstOrThrow).toHaveBeenCalledWith({
        where: { id: mockProduct.id },
      });
      expect(result).toStrictEqual(mockProduct);
    });

    it("throw nest's HttpException error when product not found", async () => {
      jest.spyOn(prismaService.product, 'findFirstOrThrow').mockRejectedValue(
        new PrismaClientKnownRequestError('No Product Found', {
          code: 'P2025',
          clientVersion: '5.0.0',
        }),
      );

      const id = 9999;
      const calls = async () => await service.findOne(id);

      expect(calls()).rejects.toThrow(HttpException);
      expect(calls()).rejects.toMatchObject({
        status: HttpStatus.NOT_FOUND,
      });
      expect(prismaService.product.findFirstOrThrow).toHaveBeenCalledWith({
        where: { id: id },
      });
    });

    it('re-throw exception other than not found exception from prisma', async () => {
      const prismaError = new Error('Any Prisma error');
      jest
        .spyOn(prismaService.product, 'findFirstOrThrow')
        .mockRejectedValue(prismaError);

      const id = 9999;
      const calls = async () => await service.findOne(id);

      expect(calls()).rejects.toThrow(prismaError);
      expect(prismaService.product.findFirstOrThrow).toHaveBeenCalledWith({
        where: { id: id },
      });
    });
  });

  describe('create', () => {
    it('successfully create product', async () => {
      const mockCreateProductDto = generateMockCreateProductDto();
      const mockProduct = generateMockProduct({
        ...mockCreateProductDto,
      });

      jest
        .spyOn(prismaService.product, 'create')
        .mockResolvedValue(mockProduct);

      const result = await service.create(mockCreateProductDto);

      expect(prismaService.product.create).toHaveBeenCalledWith({
        data: mockCreateProductDto,
      });
      expect(result).toStrictEqual(mockProduct);
    });

    test.each([
      {
        prismaError: new PrismaClientKnownRequestError('Conflict', {
          code: 'P2002',
          clientVersion: '5.0.0',
        }),
        expectedException: HttpException,
        expectedExceptionAttr: { status: HttpStatus.CONFLICT },
        message: 'product already exist',
      },
      {
        prismaError: new Error('Other Prisma Exception'),
        expectedException: Error,
        expectedExceptionAttr: {},
        message: 'there are unhandled prisma error',
      },
    ])(
      'should re-throw $expectedException with $expectedExceptionAttr when $message',
      async ({ prismaError, expectedException, expectedExceptionAttr }) => {
        const mockCreateProductDto = generateMockCreateProductDto();
        jest
          .spyOn(prismaService.product, 'create')
          .mockRejectedValue(prismaError);

        const calls = async () => await service.create(mockCreateProductDto);

        expect(calls()).rejects.toThrow(expectedException);
        expect(calls()).rejects.toMatchObject(expectedExceptionAttr);
        expect(prismaService.product.create).toHaveBeenCalledWith({
          data: mockCreateProductDto,
        });
      },
    );
  });

  describe('update', () => {
    it('successfully update product', async () => {
      const mockUpdateProductDto = generateMockUpdateProductDto();
      const mockProduct = generateMockProduct({
        ...mockUpdateProductDto,
      });

      jest
        .spyOn(prismaService.product, 'update')
        .mockResolvedValue(mockProduct);

      const result = await service.update(mockProduct.id, mockUpdateProductDto);

      expect(prismaService.product.update).toHaveBeenCalledWith({
        where: { id: mockProduct.id },
        data: mockUpdateProductDto,
      });
      expect(result).toStrictEqual(mockProduct);
    });

    test.each([
      {
        prismaError: new PrismaClientKnownRequestError('Not Found', {
          code: 'P2025',
          clientVersion: '5.0.0',
        }),
        expectedException: HttpException,
        expectedExceptionAttr: { status: HttpStatus.NOT_FOUND },
        message: 'product not found',
      },
      {
        prismaError: new PrismaClientKnownRequestError('Conflict', {
          code: 'P2002',
          clientVersion: '5.0.0',
        }),
        expectedException: HttpException,
        expectedExceptionAttr: { status: HttpStatus.CONFLICT },
        message: 'product already exist',
      },
      {
        prismaError: new Error('Other Prisma Exception'),
        expectedException: Error,
        expectedExceptionAttr: {},
        message: 'there are unhandled prisma error',
      },
    ])(
      'should re-throw $expectedException with $expectedExceptionAttr when $message',
      async ({ prismaError, expectedException, expectedExceptionAttr }) => {
        const mockUpdateProductDto = generateMockUpdateProductDto();
        jest
          .spyOn(prismaService.product, 'update')
          .mockRejectedValue(prismaError);

        const calls = async () =>
          await service.update(9999, mockUpdateProductDto);

        expect(calls()).rejects.toThrow(expectedException);
        expect(calls()).rejects.toMatchObject(expectedExceptionAttr);
        expect(prismaService.product.update).toHaveBeenCalledWith({
          where: { id: 9999 },
          data: mockUpdateProductDto,
        });
      },
    );
  });

  describe('delete', () => {
    it('successfully delete product (and return empty object)', async () => {
      const mockProduct = generateMockProduct();

      jest
        .spyOn(prismaService.product, 'delete')
        .mockResolvedValue(mockProduct);

      const result = await service.delete(mockProduct.id);

      expect(prismaService.product.delete).toHaveBeenCalledWith({
        where: { id: mockProduct.id },
      });
      expect(result).toStrictEqual({});
    });

    test.each([
      {
        prismaError: new PrismaClientKnownRequestError('Not Found', {
          code: 'P2025',
          clientVersion: '5.0.0',
        }),
        expectedException: HttpException,
        expectedExceptionAttr: { status: HttpStatus.NOT_FOUND },
        message: 'product not found',
      },
      {
        prismaError: new Error('Other Prisma Exception'),
        expectedException: Error,
        expectedExceptionAttr: {},
        message: 'there are unhandled prisma error',
      },
    ])(
      'should re-throw $expectedException with $expectedExceptionAttr when $message',
      async ({ prismaError, expectedException, expectedExceptionAttr }) => {
        const mockProduct = generateMockProduct();
        jest
          .spyOn(prismaService.product, 'delete')
          .mockRejectedValue(prismaError);

        const calls = async () => await service.delete(mockProduct.id);

        expect(calls()).rejects.toThrow(expectedException);
        expect(calls()).rejects.toMatchObject(expectedExceptionAttr);
        expect(prismaService.product.delete).toHaveBeenCalledWith({
          where: { id: mockProduct.id },
        });
      },
    );
  });
});
