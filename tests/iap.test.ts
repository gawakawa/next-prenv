import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { verifyIapAssertion } from '../src/lib/iap';

describe('verifyIapAssertion', () => {
	const originalBypass = process.env.AUTH_DEV_BYPASS;
	const originalAudience = process.env.IAP_AUDIENCE;

	beforeEach(() => {
		delete process.env.AUTH_DEV_BYPASS;
		delete process.env.IAP_AUDIENCE;
	});

	afterEach(() => {
		if (originalBypass === undefined) {
			delete process.env.AUTH_DEV_BYPASS;
		} else {
			process.env.AUTH_DEV_BYPASS = originalBypass;
		}
		if (originalAudience === undefined) {
			delete process.env.IAP_AUDIENCE;
		} else {
			process.env.IAP_AUDIENCE = originalAudience;
		}
	});

	it('rejects a missing assertion when the dev bypass is off', async () => {
		expect(await verifyIapAssertion(undefined)).toBeUndefined();
	});

	it('returns a dev user for a missing assertion when the dev bypass is on', async () => {
		process.env.AUTH_DEV_BYPASS = '1';
		expect(await verifyIapAssertion(undefined)).toEqual({ id: 'dev', email: 'dev@localhost' });
	});

	it('rejects a garbage assertion', async () => {
		process.env.IAP_AUDIENCE = '/projects/123/locations/asia-northeast1/services/next-prenv-pr-1';
		expect(await verifyIapAssertion('not-a-jwt')).toBeUndefined();
	});

	it('fails closed when IAP_AUDIENCE is unset, even with a present assertion', async () => {
		expect(await verifyIapAssertion('some.assertion.value')).toBeUndefined();
	});
});
