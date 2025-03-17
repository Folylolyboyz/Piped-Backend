# ---- Build Stage ----
FROM eclipse-temurin:21-jdk AS build

WORKDIR /app/

# Copy project files
COPY . /app/

# Use Railway's expected cache key format
RUN --mount=type=cache,id=cache-gradle,target=/root/.gradle/caches \
    --mount=type=cache,id=cache-gradle-wrapper,target=/root/.gradle/wrapper \
    ./gradlew shadowJar

# ---- Runtime Stage ----
FROM eclipse-temurin:21-jre

# Use Railway's expected cache key format for APT packages
RUN --mount=type=cache,id=cache-apt,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app/

# Copy necessary files from the build stage
COPY hotspot-entrypoint.sh docker-healthcheck.sh /
COPY --from=build /app/build/libs/piped-1.0-all.jar /app/piped.jar
COPY VERSION .

EXPOSE 8080

# Health check for container
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD /docker-healthcheck.sh

# Set entrypoint
ENTRYPOINT ["/hotspot-entrypoint.sh"]
