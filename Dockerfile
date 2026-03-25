# Dockerfile — PregnaCare API (production)
FROM node:20-alpine AS base
WORKDIR /app

# Install dependencies layer (cached unless package.json changes)
FROM base AS deps
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Final image
FROM base AS runner
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s \
  CMD wget -qO- http://localhost:3000/api/v1/health || exit 1

CMD ["node", "src/server.js"]
