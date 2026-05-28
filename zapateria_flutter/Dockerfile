FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /flutter
ENV PATH="/flutter/bin:$PATH"

RUN flutter precache --web --no-android --no-ios --no-linux --no-macos --no-windows

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .

RUN flutter build web --release

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
