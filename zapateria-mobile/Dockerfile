FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 8081 19000 19001 19002

CMD ["npx", "expo", "start", "--lan", "--non-interactive", "--port", "8081"]