import { createRemoteJWKSet, jwtVerify } from 'jose';

const JWKS = createRemoteJWKSet(new URL('https://www.gstatic.com/iap/verify/public_key-jwk'));

export type IapUser = { id: string; email: string };

/**
 * Verifies the `x-goog-iap-jwt-assertion` header IAP signs onto every
 * request it forwards. This is the only source of identity — the unsigned
 * `x-goog-authenticated-user-email` header is never used.
 */
export const verifyIapAssertion = async (
	assertion: string | undefined,
): Promise<IapUser | undefined> => {
	// Local development only. Opt-in and fail-closed: without this variable an
	// absent assertion is always a rejection.
	if (!assertion) {
		return process.env.AUTH_DEV_BYPASS ? { id: 'dev', email: 'dev@localhost' } : undefined;
	}

	const audience = process.env.IAP_AUDIENCE;
	// jose skips the audience check when this is undefined, which would accept
	// an assertion minted for another service.
	if (!audience) return undefined;

	try {
		const { payload } = await jwtVerify(assertion, JWKS, {
			issuer: 'https://cloud.google.com/iap',
			audience,
		});
		return typeof payload.sub === 'string' && typeof payload.email === 'string'
			? { id: payload.sub, email: payload.email }
			: undefined;
	} catch {
		return undefined;
	}
};
