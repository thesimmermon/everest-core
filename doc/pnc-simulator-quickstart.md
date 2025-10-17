# Plug & Charge Simulator Quickstart

This guide shows how to run the EVerest software-in-the-loop (SIL) Plug & Charge
simulator that acts as an EV. The demo uses the `EvManager` car simulator, the
`PyEvJosev` ISO 15118 stack, and the Yeti hardware simulator to execute a
full Plug & Charge charging session without any external hardware.

The quickstart is intentionally task-focused: follow the steps below and you
will have a simulated EV connecting to the EVerest charging stack, requesting
contract installation, and drawing power automatically.

## Repository layout

The demo adds three helper artifacts on top of the existing modules:

* `config/config-sil-pnc-demo.yaml` – lean configuration that wires together the
  EV simulator, ISO 15118 communication stack, energy routing, and authorization
  to perform a Plug & Charge session automatically.
* `scripts/run_pnc_demo.sh` – one-line launcher that starts the EVerest runtime
  (`manager`) with the demo configuration and stores logs in `logs/pnc-demo`.
* `docker/pnc-demo/Dockerfile` – optional container image recipe that packages
  a pre-built installation so the simulator can run in a container.

## Prerequisites

The demo assumes that you already cloned the EVerest workspace and installed the
project dependencies. If this is your first time working with EVerest, follow
the [workspace setup](../README.md#build--install) to install EDM, initialize the
workspace, and build `everest-core`.

Before running the simulator ensure that:

1. `everest-core` has been built and installed (`make install`) in the
   repository `build/dist` folder (or another prefix that you provide via the
   `EVEREST_PREFIX` environment variable).
2. The auto-generated ISO 15118 certificates exist in `config/certs` (this
   happens automatically during the build unless you disabled certificate
   generation).

## Run the simulator on the host

1. Open a terminal inside the `everest-core` repository root.
2. Build and install if you have not done so yet:

   ```bash
   mkdir -p build && cd build
   cmake ..
   make install
   cd ..
   ```

3. Start the Plug & Charge simulator:

   ```bash
   ./scripts/run_pnc_demo.sh
   ```

   The script prints the active configuration and writes runtime logs to
   `logs/pnc-demo/everest.log`. All Plug & Charge XML transcripts from the ISO
   15118 session appear in `/tmp/everest-logs`.

4. Wait for the simulator to complete the scripted session. The default command
   sequence performs SLAC matching, starts ISO 15118, requests power, keeps the
   session alive for 30 seconds, and then disconnects. You can watch the progress
   in the log file while it runs:

   ```bash
   tail -f logs/pnc-demo/everest.log
   ```

5. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> to stop the simulator once the session has
   finished. The final energy and authorization results are written to the log
   and to `/tmp/everest-logs`.

### Adjusting the behavior

* To run a different command sequence, either edit
  `config/config-sil-pnc-demo.yaml` or pass an alternative configuration to the
  launcher:

  ```bash
  ./scripts/run_pnc_demo.sh path/to/your-config.yaml
  ```

* Forward extra runtime options (for example to increase log verbosity) via the
  `EVEREST_EXTRA_ARGS` environment variable:

  ```bash
  EVEREST_EXTRA_ARGS="--log-level debug" ./scripts/run_pnc_demo.sh
  ```

* If you installed EVerest into a custom prefix, point the launcher at it via
  `EVEREST_PREFIX`:

  ```bash
  EVEREST_PREFIX=$HOME/everest/install ./scripts/run_pnc_demo.sh
  ```

## Run the simulator in a container

The repository also provides `docker/pnc-demo/Dockerfile`, which packages an
existing build into a lightweight runtime image. The Dockerfile uses the
public `ghcr.io/everest/everest-dev-environment/runtime` base image that already
contains the system dependencies required by `manager` and the Python-based EV
stack.

1. Build and install `everest-core` on the host so that `build/dist` contains the
   runtime artifacts.
2. Build the container image from the repository root:

   ```bash
   docker build \
  --build-arg BASE_IMAGE=ghcr.io/everest/everest-dev-environment/runtime:docker-images-v0.1.0 \
  -t everest-pnc-demo \
  -f docker/pnc-demo/Dockerfile .
   ```

   You can override `BASE_IMAGE` to match the runtime image version you use in
   your environment.

3. Run the simulator container. It exposes the same launcher script as the host
   version, so you can override configuration or add extra arguments via
   environment variables:

   ```bash
   docker run --rm --name pnc-demo \
  -e EVEREST_EXTRA_ARGS="--log-level info" \
  everest-pnc-demo
   ```

   Runtime logs are written inside the container to `/opt/everest/logs/pnc-demo`.
   Use `docker logs pnc-demo` (or bind mount a host directory to `/opt/everest/logs`) to
   inspect them while the container is running.

4. Stop the simulator with `Ctrl+C` (if attached) or `docker stop pnc-demo` from
   another terminal.

## Next steps

* Explore the generated session logs under `/tmp/everest-logs` to analyze ISO
  15118 communication and Plug & Charge authorization results.
* Connect the simulated EV to other EVerest configurations by updating the
  `active_modules` section in `config/config-sil-pnc-demo.yaml`.
* Extend the scripted EV behavior by editing the `auto_exec_commands` string in
  the configuration. The available commands are documented in
  `modules/EV/EvManager/doc.rst`.
