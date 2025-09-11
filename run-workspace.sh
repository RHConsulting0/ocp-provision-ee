#!/bin/bash

docker run --rm -it \
  -v ~/ocp-workdir:/workdir \
  aap-ee-ocp4.18-optimized
