import { headers } from 'next/headers';
import { signIn } from '../../auth';

// IAP has already authenticated the request by the time it reaches here, so
// this establishes the app's own session without asking the user to click
// anything.
export const GET = async (request: Request) => {
	const assertion = (await headers()).get('x-goog-iap-jwt-assertion');
	const to = new URL(request.url).searchParams.get('to');
	// Only relative paths, to keep this from becoming an open redirect.
	const redirectTo = to?.startsWith('/') && !to.startsWith('//') ? to : '/';

	// `?? ''` matters: signIn serializes credential fields through a form
	// body, so a missing value would reach authorize() as the string "null" —
	// truthy, so the AUTH_DEV_BYPASS branch in verifyIapAssertion would never
	// run.
	return signIn('iap', { assertion: assertion ?? '', redirectTo });
};
