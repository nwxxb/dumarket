import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { recentDate } from './matchers/date.matcher';
import { PrismaService } from 'src/prisma/prisma.service';
import { resetDatabase } from './helpers/reset-database.helper';
import { PrismaClient } from 'generated/prisma/client';

describe('products resources', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    prisma = app.get(PrismaService);
    await app.init();
  });

  beforeEach(async () => {
    await resetDatabase(prisma);
  });

  afterAll(async () => {
    await prisma.$disconnect();
    await app.close();
  });

  describe('/products (POST)', () => {
    it('request body invalid', async () => {
      const response = await request(app.getHttpServer())
        .post('/products')
        .send({ description: 'a shoes', price: 10 });

      expect(response.status).toEqual(400);
    });

    it('product created successfully', async () => {
      const response = await request(app.getHttpServer())
        .post('/products')
        .send({ name: 'Shoes', description: 'a shoes', price: 10 })
        .expect(201);

      expect(response.body).toMatchObject({
        id: expect.any(Number),
        name: 'Shoes',
        description: 'a shoes',
        price: 10,
        createdAt: recentDate(),
        updatedAt: recentDate(),
      });
    });
  });

  describe('/products (GET)', () => {
    it('fetch products successfully', async () => {
      const product1 = await prisma.product.create({
        data: {
          name: 'Food',
          description: 'a food',
          price: 10,
        },
      });
      const product2 = await prisma.product.create({
        data: {
          name: 'Shoes',
          description: 'a shoes',
          price: 11,
        },
      });

      const response = await request(app.getHttpServer()).get('/products');

      expect(response.status).toEqual(200);
      expect(response.body).toMatchObject([
        {
          ...product1,
          id: expect.any(Number),
          createdAt: recentDate(),
          updatedAt: recentDate(),
        },
        {
          ...product2,
          id: expect.any(Number),
          createdAt: recentDate(),
          updatedAt: recentDate(),
        },
      ]);
    });
  });

  describe('/products/:id (GET)', () => {
    it('product not found', async () => {
      const response = await request(app.getHttpServer()).get(
        `/products/${9999}`,
      );

      expect(response.status).toEqual(404);
      expect(response.body.message).toMatch(/not.*found/i);
    });

    it('product found', async () => {
      const product = await prisma.product.create({
        data: {
          name: 'Food',
          description: 'a food',
          price: 10,
        },
      });

      const response = await request(app.getHttpServer()).get(
        `/products/${product.id}`,
      );

      expect(response.status).toEqual(200);
      expect(response.body).toMatchObject({
        ...product,
        createdAt: recentDate(),
        updatedAt: recentDate(),
      });
    });
  });

  describe('/products/:id (PUT)', () => {
    it('product not found', async () => {
      const response = await request(app.getHttpServer())
        .put(`/products/${9999}`)
        .send({});

      expect(response.status).toEqual(404);
      expect(response.body.message).toMatch(/not.*found/i);
    });

    it('request body invalid', async () => {
      const product = await prisma.product.create({
        data: {
          name: 'Food',
          description: 'a food',
          price: 10,
        },
      });
      const newProductData = {
        price: 'a string',
      };

      const response = await request(app.getHttpServer())
        .put(`/products/${product.id}`)
        .send(newProductData);

      expect(response.status).toEqual(400);
    });

    it('updated successfully', async () => {
      const product = await prisma.product.create({
        data: {
          name: 'Food',
          description: 'a food',
          price: 10,
        },
      });
      const newProductData = {
        name: 'Delicious Food',
        description: 'a delicious food',
      };

      const response = await request(app.getHttpServer())
        .put(`/products/${product.id}`)
        .send(newProductData);

      expect(response.status).toEqual(200);
      expect(response.body).toMatchObject({
        ...product,
        ...newProductData,
        createdAt: recentDate(),
        updatedAt: recentDate(),
      });
      expect(new Date(response.body.createdAt).getTime()).toBeLessThan(
        new Date(response.body.updatedAt).getTime(),
      );
    });
  });

  describe('/products/:id (DELETE)', () => {
    it('product not found', async () => {
      const response = await request(app.getHttpServer()).delete(
        `/products/${9999}`,
      );

      expect(response.status).toEqual(404);
      expect(response.body.message).toMatch(/not.*found/i);
    });

    it('deleted successfully', async () => {
      const product = await prisma.product.create({
        data: {
          name: 'Food',
          description: 'a food',
          price: 10,
        },
      });

      const response = await request(app.getHttpServer()).delete(
        `/products/${product.id}`,
      );

      expect(response.status).toEqual(204);
      expect(response.body).toMatchObject({});
      expect(
        await prisma.product.findFirst({ where: { id: product.id } }),
      ).toBeNull();
    });
  });
});
