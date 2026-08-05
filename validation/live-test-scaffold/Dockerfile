# Disposable, network-restricted environment for live-agent testing of the
# reality-filter-protocol v1.3.0 technical controls against a real DevSwarm
# orchestration. Never point a live multi-agent run at the production
# Cerebro-Queen workspace directly -- run it here first.
#
# Build:  docker build -t reality-filter-livetest .
# Run:    docker run --rm -it --network none -v "$(pwd)/repo:/work" reality-filter-livetest
#         (drop --network none only for the specific step that needs the
#         model API; re-add it for everything else)

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git config --global user.email "livetest@isolated.local" \
    && git config --global user.name "reality-filter-livetest"

WORKDIR /work

COPY setup-isolated-repo.sh /usr/local/bin/setup-isolated-repo.sh
RUN chmod +x /usr/local/bin/setup-isolated-repo.sh

ENTRYPOINT ["/bin/bash"]
