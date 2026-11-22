FROM python:3.12.16-slim-trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl socat \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data /app

WORKDIR /app
