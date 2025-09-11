#!/bin/bash

docker run --rm -it \
  -v ~/ocp-workdir:/workdir \
  ocp-provision-ee:latest
