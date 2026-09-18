#!/usr/bin/env bash
# Runs the full LibreLane flow (RTL -> GDSII) using config.yaml in this
# same directory. Output lands in targets/librelane/runs/<timestamp>/.
set -e
cd "$(dirname "$0")"
librelane config.yaml
