FROM ubuntu:22.04

# Prerequisites
RUN apt update && apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev

# Download Flutter SDK from official source
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app

# Create non-root user
RUN useradd -ms /bin/bash flutteruser
RUN chown -R flutteruser:flutteruser /usr/local/flutter /app
USER flutteruser
COPY pubspec.yaml .
RUN flutter pub get

COPY . .

# Enable web explicitly for manually created folders
RUN flutter create . --platforms web
# Build for web
RUN flutter build web

# Use Nginx to serve the static built flutter app
FROM nginx:alpine
COPY --from=0 /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
