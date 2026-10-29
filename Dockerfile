# Stage 1 — Build backend & frontend
FROM node:20-bullseye AS build

# Set working directory to where you want to run yarn commands
WORKDIR /app/backstage

# Copy everything from your repo into /app
COPY . /app

# Enable Corepack & Yarn
RUN corepack enable && corepack prepare yarn@4.4.1 --activate

# Install dependencies and build
RUN yarn install --immutable
RUN yarn tsc
RUN yarn build:backend

# Stage 2 — Runtime image
FROM node:20-bookworm-slim AS runtime

# Set Python interpreter for node-gyp to use
ENV PYTHON=/usr/bin/python3

# Install isolate-vm dependencies (needed by scaffolder backend)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 g++ build-essential && \
    rm -rf /var/lib/apt/lists/*

# Use non-root user
USER node

WORKDIR /app

# Copy yarn config
COPY --from=build --chown=node:node /app/backstage/.yarn ./.yarn
COPY --from=build --chown=node:node /app/backstage/.yarnrc.yml ./
COPY --from=build --chown=node:node /app/backstage/backstage.json ./

# Set production env
ENV NODE_ENV=production
ENV NODE_OPTIONS="--no-node-snapshot"

# Copy and extract skeleton (for production node_modules install)
COPY --from=build --chown=node:node /app/backstage/packages/backend/dist/skeleton.tar.gz ./
COPY --from=build --chown=node:node /app/backstage/yarn.lock ./
COPY --from=build --chown=node:node /app/backstage/package.json ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

# Install production-only dependencies
RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    yarn workspaces focus --all --production && rm -rf "$(yarn cache clean)"

# Copy examples and templates
COPY --from=build --chown=node:node /app/backstage/examples ./examples
COPY --from=build --chown=node:node /app/backstage/templates ./templates
# Copy backend bundle + configs
COPY --from=build --chown=node:node /app/backstage/packages/backend/dist/bundle.tar.gz ./
COPY --from=build --chown=node:node /app/backstage/app-config*.yaml ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Start backend
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
