#!/bin/bash

docker run --rm -it \
  -v {location}/install-dir:/runner/project/install-dir \
  ocp-provision-ee:latest
