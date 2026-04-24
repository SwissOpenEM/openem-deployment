#!/bin/bash
# Wrapper for running docker compose commands over multiple deployments
# Must be run from the openem-deployment directory

set +x
set -euo pipefail
IFS=$'\n\t'

usage () {
  cat <<END
Usage: $0 [-h] [DEPLOYMENT(S)] [DOCKER_COMMAND]
  DEPLOYMENTS: one or more of 'proxy' 'production' 'qa' 'dev' (default: production qa dev)
  DOCKER_COMMAND: any docker compose command, e.g. "up -d" or "logs -f"
END
}

DEPLOYMENTS=()
ALL_DEPLOYMENTS=("production" "qa" "dev")
PROXY=false

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    proxy)
      PROXY=true
      shift
      ;;
    all)
      DEPLOYMENTS=("${ALL_DEPLOYMENTS[@]}")
      PROXY=true
      shift
      ;;
    dev|qa|production)
      DEPLOYMENTS+=("$1")
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      # Break on the first unrecognized argument, which should be the start of the docker command
      break
      ;;
  esac
done

# default environments
[[ ${#DEPLOYMENTS[@]} -eq 0 ]] && [[ $PROXY != "true" ]] && DEPLOYMENTS=("production" "dev" "qa")
echo "DEPLOYMENTS: ${DEPLOYMENTS[@]}"

if [ $# -eq 0 ]; then
  echo "Error: No docker command provided" >&2
  usage >&2
  exit 1
fi

# Ensure the 'ingestor-net' network exists
if ! docker network inspect ingestor-net >/dev/null 2>&1; then
  (
    set -x
    docker network create ingestor-net
  )
fi

# Start ingestor instances
for DEPLOYMENT in "${DEPLOYMENTS[@]}"; do
  echo "Running on $DEPLOYMENT"
  CMD=(docker compose -p ingestor-$DEPLOYMENT -f services/ingestor/compose.yaml)
  ENV_FILES=(
    "services/ingestor/config/$DEPLOYMENT/env.$DEPLOYMENT"
    ".env"
    ".env.$DEPLOYMENT"
  )
  for ENV_FILE in "${ENV_FILES[@]}"; do
    if [ -f "$ENV_FILE" ]; then
      CMD+=(--env-file "$ENV_FILE")
    fi
  done

  # subshell with command tracing
  (
    set -x
    "${CMD[@]}" "$@"
  )

done

if [ "$PROXY" = true ]; then
  echo "Starting proxy"
  docker compose -p ingestor-proxy \
    --profile with_proxy \
    --env-file .env \
    -f services/proxy/compose.yaml \
    "$@" proxy
fi
