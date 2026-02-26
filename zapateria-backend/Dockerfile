# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Create uploads directory with proper permissions
RUN mkdir -p uploads/zapatos && chmod -R 755 uploads

# Create uploads directory
RUN mkdir -p uploads

# Expose port
EXPOSE 3000

# Set user for security
USER node

# Start the application
CMD ["node", "dist/main"]