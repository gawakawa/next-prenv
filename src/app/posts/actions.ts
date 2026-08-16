'use server';

import { revalidatePath } from 'next/cache';
import { prisma } from '../../lib/prisma';

export const createPost = async (formData: FormData): Promise<void> => {
	const title = formData.get('title');
	if (typeof title !== 'string' || title.trim() === '') {
		return;
	}

	await prisma.post.create({ data: { title } });
	revalidatePath('/posts');
};
