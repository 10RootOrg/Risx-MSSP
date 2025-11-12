# reconftw

Docker resources for deploying [six2dez/reconftw](https://github.com/six2dez/reconftw) within the 10root stack. The container bundles a web terminal powered by [ttyd](https://github.com/tsl0922/ttyd) so the CLI can be accessed from the browser via the platform reverse proxy. The upstream image only targets `linux/amd64`, so the compose file and wrapper image pin to that platform when building and running the service.

## Files

- `Dockerfile` – builds a thin wrapper image on top of `six2dez/reconftw` and injects ttyd for web access.
- `entrypoint.sh` – starts ttyd and launches a writable shell session.
- `docker-compose.yml` – defines the single service used by the stack.
- `.env` – default environment variables consumed by the compose file.

## Usage

The service runs inside the shared `main_network` and will be exposed through Nginx at `/reconftw/`. Output and configuration are persisted to the `data` and `config` sub-directories created alongside the compose file.
