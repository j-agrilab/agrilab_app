# --- Stage 1: Build the Flutter App ---
# Use a base image that contains all the necessary tools to build a Flutter app.
FROM cirrusci/flutter:latest AS build-env

# Set the working directory inside the container
WORKDIR /app

# Copy the pubspec.yaml and pubspec.lock files to install dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the app's source code
COPY . .

# Build the Flutter web application in release mode
RUN flutter build web --release

# --- Stage 2: Serve the App with Nginx ---
# Use a lightweight web server image to serve the static files
FROM nginx:alpine

# Copy the built files from the 'build-env' stage to the Nginx web root
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose the default HTTP port
EXPOSE 80

# Start the Nginx server when the container runs
CMD ["nginx", "-g", "daemon off;"]