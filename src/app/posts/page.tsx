import { auth } from '../../auth';
import { prisma } from '../../lib/prisma';
import { createPost } from './actions';

export const dynamic = 'force-dynamic';

export default async function Posts() {
	const [session, posts] = await Promise.all([
		auth(),
		prisma.post.findMany({ orderBy: { createdAt: 'desc' } }),
	]);

	return (
		<div className="flex flex-col flex-1 items-center bg-zinc-50 font-sans dark:bg-black">
			<main className="flex w-full max-w-3xl flex-col gap-8 py-32 px-16">
				<h1 className="text-3xl font-semibold tracking-tight text-black dark:text-zinc-50">
					Posts
				</h1>
				<p className="text-sm text-black/60 dark:text-zinc-400">
					Signed in as {session?.user?.email}
				</p>
				<form action={createPost} className="flex gap-2">
					<input
						type="text"
						name="title"
						placeholder="New post title"
						required
						className="flex-1 rounded border border-black/[.08] px-3 py-2 dark:border-white/[.145] dark:bg-black dark:text-zinc-50"
					/>
					<button
						type="submit"
						className="rounded bg-foreground px-4 py-2 text-background hover:bg-[#383838] dark:hover:bg-[#ccc]"
					>
						Add
					</button>
				</form>
				<ul className="flex flex-col gap-2">
					{posts.map((post) => (
						<li
							key={post.id}
							className="rounded border border-black/[.08] px-4 py-2 dark:border-white/[.145]"
						>
							{post.title}
						</li>
					))}
				</ul>
			</main>
		</div>
	);
}
