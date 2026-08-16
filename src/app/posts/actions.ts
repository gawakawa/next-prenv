'use server';

import { revalidatePath } from 'next/cache';
import { auth } from '../../auth';
import { prisma } from '../../lib/prisma';

export const createPost = async (formData: FormData): Promise<void> => {
	// Don't rely on middleware alone (it can be bypassed — see CVE-2025-29927);
	// re-check on the Server Action that actually writes data.
	const session = await auth();
	if (!session) {
		throw new Error('Unauthorized');
	}

	const title = formData.get('title');
	if (typeof title !== 'string' || title.trim() === '') {
		return;
	}

	await prisma.post.create({ data: { title } });
	revalidatePath('/posts');
};
