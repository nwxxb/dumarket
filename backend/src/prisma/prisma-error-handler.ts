import { HttpException, HttpStatus } from '@nestjs/common';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/client';

export class PrismaErrorHandler {
  static handle(error: unknown, resourceName = 'Resource'): never {
    if (error instanceof PrismaClientKnownRequestError) {
      switch (error.code) {
        case 'P2002':
          throw new HttpException(
            `${resourceName} already exists`,
            HttpStatus.CONFLICT,
          );
        case 'P2025':
          throw new HttpException(
            `${resourceName} not found`,
            HttpStatus.NOT_FOUND,
          );
        case 'P2003':
          throw new HttpException(`Invalid reference`, HttpStatus.BAD_REQUEST);
        default:
          throw new HttpException(`Invalid input`, HttpStatus.BAD_REQUEST);
      }
    }
    throw error;
  }
}
