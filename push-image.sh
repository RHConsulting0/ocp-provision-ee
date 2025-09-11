#!/bin/sh 
IMAGE_NAME=$1
TARGET_REGISTRY="quay.io/redhat_emp1"
CREDS_FILE="/home/miryan/.docker/auth.json"
CURRENT_DIR=$(pwd -P)


startTs=$(date +"%c")
printf ">>>> Push to quay.io start @ $startTs <<<<\n" 
startTs=$SECONDS

podman login --authfile=$CREDS_FILE quay.io

skopeo copy --src-no-creds --insecure-policy --src-tls-verify=false --dest-authfile $CREDS_FILE containers-storage:localhost/$IMAGE_NAME docker://$TARGET_REGISTRY/$IMAGE_NAME

skopeo inspect --authfile=$CREDS_FILE --insecure-policy --tls-verify=false docker://$TARGET_REGISTRY/$IMAGE_NAME

endTs=$(date +"%c")
printf ">>>> Push to quay.io end @ $endTs <<<<\n\n" 
elapsed=$(( SECONDS - startTs ))
eval "echo !!Elapsed time!!: $(date -ud "@$elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec')"
