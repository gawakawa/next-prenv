import NextAuth from 'next-auth';
import Credentials from 'next-auth/providers/credentials';
import { verifyIapAssertion } from './lib/iap';

export const { handlers, auth, signIn, signOut } = NextAuth({
	trustHost: true,
	// Credentials provider requires the JWT strategy (no database sessions).
	// Kept short so revoking roles/iap.httpsResourceAccessor takes effect
	// quickly — the session cookie otherwise outlives the IAP grant.
	session: { strategy: 'jwt', maxAge: 60 * 60 },
	providers: [
		Credentials({
			id: 'iap',
			name: 'Identity-Aware Proxy',
			credentials: { assertion: {} },
			authorize: async ({ assertion }) => {
				const user = await verifyIapAssertion(
					typeof assertion === 'string' ? assertion : undefined,
				);
				// authorize()'s return type is fixed by next-auth to `User | null`.
				// eslint-disable-next-line unicorn/no-null
				return user ?? null;
			},
		}),
	],
});
