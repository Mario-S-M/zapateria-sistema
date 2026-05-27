# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=512"

COPY package*.json ./

RUN npm install --legacy-peer-deps

COPY . .

RUN npm run build

# Production stage
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_OPTIONS="--max-old-space-size=512"

COPY package*.json ./

RUN npm install --omit=dev --legacy-peer-deps && npm cache clean --force

COPY --from=builder /app/dist ./dist

RUN mkdir -p uploads/zapatos && chmod -R 755 uploads

EXPOSE 3000

USER node

CMD ["node", "dist/main"]
