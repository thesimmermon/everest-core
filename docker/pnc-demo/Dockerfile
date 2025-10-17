# Container image for the Plug & Charge demo EV simulator
# The base image provides the EVerest runtime dependencies.
ARG BASE_IMAGE=ghcr.io/everest/everest-dev-environment/runtime:docker-images-v0.1.0
FROM ${BASE_IMAGE}

ENV EVEREST_PREFIX=/opt/everest
WORKDIR ${EVEREST_PREFIX}

# Copy the pre-built everest-core installation into the image.
COPY build/dist/ ${EVEREST_PREFIX}/
# Include the demo configuration and helper script for convenience.
COPY config/config-sil-pnc-demo.yaml ${EVEREST_PREFIX}/config/config-sil-pnc-demo.yaml
COPY scripts/run_pnc_demo.sh /usr/local/bin/run_pnc_demo.sh

RUN mkdir -p /var/log/everest \
    && chmod +x /usr/local/bin/run_pnc_demo.sh

ENTRYPOINT ["/usr/local/bin/run_pnc_demo.sh"]
CMD []
