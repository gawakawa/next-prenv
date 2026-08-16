import { auth } from './auth';

export default auth((request) => {
	if (request.auth) return;

	const to = request.nextUrl.pathname + request.nextUrl.search;
	return Response.redirect(new URL(`/signin?to=${encodeURIComponent(to)}`, request.nextUrl));
});

export const config = {
	// api/auth and signin must be excluded or the redirect loops.
	matcher: ['/((?!api/auth|signin|_next/static|_next/image|favicon.ico).*)'],
};
