import { PrismaClient } from '../src/generated/prisma/index.js';

const prisma = new PrismaClient();

const titles = ['Hello Prisma', 'Connected to MySQL', 'Seeded via pnpm seed'];

await prisma.post.createMany({
	data: titles.map((title) => ({ title })),
	skipDuplicates: true,
});

console.log(`Seeded ${titles.length} posts (duplicates skipped).`);

await prisma.$disconnect();
