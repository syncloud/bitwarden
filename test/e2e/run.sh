#!/bin/bash -e
# usage: run.sh <artifact-subdir> <spec>
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

ARTIFACT_SUBDIR=$1
SPEC=$2

export PLAYWRIGHT_FULL_DOMAIN=bookworm.com
export PLAYWRIGHT_APP_DOMAIN=bitwarden.bookworm.com
export PLAYWRIGHT_DEVICE_HOST=bitwarden.bookworm.com
export PLAYWRIGHT_DEVICE_USER=user
export PLAYWRIGHT_DEVICE_PASSWORD=Password1
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/${ARTIFACT_SUBDIR}

apt-get update -qq
apt-get install -y -qq sshpass openssh-client curl
npm ci --no-audit --no-fund
npx playwright test --project=desktop "$SPEC"
