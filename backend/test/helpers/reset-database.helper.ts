import { PrismaClient } from 'generated/prisma/client';

export async function resetDatabase(prisma: PrismaClient) {
  const tables = await prisma.$queryRaw<Array<{ tablename: string }>>`
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
  `;

  await prisma.$executeRawUnsafe(`SET session_replication_role = replica;`);

  for (const { tablename } of tables) {
    if (tablename !== '_prisma_migrations') {
      await prisma.$executeRawUnsafe(
        `TRUNCATE TABLE "public"."${tablename}" RESTART IDENTITY CASCADE`,
      );
    }
  }

  await prisma.$executeRawUnsafe(`SET session_replication_role = DEFAULT;`);
}
