###############################################################################
# STAGE 1: BASE
###############################################################################

FROM node:20-alpine AS base
WORKDIR /app

# Install build tools and pnpm
RUN apk add --no-cache python3 make g++ cmake && \
    corepack enable && \
    corepack prepare pnpm@9.2.0 --activate

###############################################################################
# STAGE 2: INSTALL DEPENDENCIES
###############################################################################

FROM base AS deps

# Copy package files and install dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

###############################################################################
# STAGE 3: BUILD
###############################################################################

FROM deps AS build

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Copy all source files and build the application
COPY . .
RUN pnpm run build

###############################################################################
# STAGE 4: RUN
###############################################################################

FROM base AS app

WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Copy the built application and necessary files
COPY --from=deps /app/node_modules ./node_modules/
COPY --from=build /app/package.json /app/pnpm-lock.yaml ./
COPY --from=build /app/.next ./.next/
COPY --from=build /app/next.config.mjs ./
#COPY --from=build /app/public ./public/

EXPOSE 3000
CMD ["pnpm", "start"]