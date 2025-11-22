import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  describe('products', () => {
    it('/products (POST)', () => {
      return request(app.getHttpServer())
        .post('/products')
        .send({ id: 1, name: 'Shoes', description: 'a shoes', price: 10 })
        .expect(201)
        .expect({ id: 1, name: 'Shoes', description: 'a shoes', price: 10 });
    });

    it('/products (GET)', async () => {
      await request(app.getHttpServer())
        .post('/products')
        .send({ id: 1, name: 'Shoes', description: 'a shoes', price: 10 });

      return request(app.getHttpServer())
        .get('/products')
        .expect(200)
        .expect([{ id: 1, name: 'Shoes', description: 'a shoes', price: 10 }]);
    });
  });
});
