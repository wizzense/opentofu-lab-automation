#!/usr/bin/env bash
set -euo pipefail

docker build -t tofu-lab .
docker run --rm -it tofu-lab "$@"
