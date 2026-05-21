#!/bin/bash -e
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

apt-get update -qq
apt-get install -y -qq sshpass openssh-client curl
npm ci --no-audit --no-fund
npx playwright test --project=desktop "$@"
