FROM eclipse-temurin:25-jdk-jammy

RUN apt-get update \
    && apt-get install --no-install-recommends --yes coreutils perl python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /benchmark
COPY . .

RUN mkdir -p /benchmark/data /benchmark/results \
    && ./scripts/build.sh \
    && chmod -R a+rwX /benchmark

ENTRYPOINT ["./scripts/rerun.sh"]
