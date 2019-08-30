FROM buildpack-deps:stretch
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /tmp/scripts
COPY images/build/node/build.sh /tmp/scripts
RUN chmod +x /tmp/scripts/build.sh
RUN /tmp/scripts/build.sh
