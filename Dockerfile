# Adapted from the official Next.js example:
# https://github.com/vercel/next.js/tree/canary/examples/with-docker

# ============================================
# Stage 1: Dependencies Installation Stage
# ============================================

# Keep in sync with nodejs_24 in nix/toolchain.nix.
ARG NODE_VERSION=24.19.0-slim

FROM node:${NODE_VERSION} AS dependencies

WORKDIR /app

# Keep in sync with pnpmPackage in nix/toolchain.nix.
RUN corepack enable && corepack prepare pnpm@10.34.5 --activate

# Copy package-related files first to leverage Docker's caching mechanism
COPY package.json pnpm-lock.yaml .npmrc ./

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
	pnpm install --frozen-lockfile

# ============================================
# Stage 2: Build Next.js application in standalone mode
# ============================================

FROM node:${NODE_VERSION} AS builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.34.5 --activate

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

ENV NODE_ENV=production

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN pnpm build

# ============================================
# Stage 3: Run Next.js application
# ============================================

FROM node:${NODE_VERSION} AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the run time.
# ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=builder --chown=node:node /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown node:node .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/app/api-reference/config/next-config-js/output
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static

USER node

EXPOSE 3000

CMD ["node", "server.js"]
