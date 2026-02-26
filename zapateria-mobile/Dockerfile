FROM node:20-alpine

WORKDIR /app

ENV CI=1

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 8081 19000 19001 19002

CMD ["npx", "expo", "start", "--lan", "--port", "8081"]