# Agent image for the A/B study. Contains tools only -- nothing about the
# study, the tasks, the protocol or the arms. An agent running in this image
# sees its workspace (/work/repo), optionally a delegation mailbox (/mailbox),
# and nothing else from the host.
#
# Every version is pinned so a run can be reproduced exactly later.
FROM node@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates procps \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system --add safe.directory '*'

RUN npm install -g @anthropic-ai/claude-code@2.1.228 @google/gemini-cli@0.61.0 \
 && npm cache clean --force

COPY worker /usr/local/bin/worker
RUN chmod 755 /usr/local/bin/worker

ENV DISABLE_AUTOUPDATER=1
USER node
WORKDIR /work
