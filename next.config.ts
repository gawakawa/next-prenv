import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
	output: 'standalone',
	// Type checking is handled by oxlint's tsgo-powered type-aware linting
	// (see .oxlintrc.json), not next build's built-in tsc check.
	typescript: {
		ignoreBuildErrors: true,
	},
};

export default nextConfig;
