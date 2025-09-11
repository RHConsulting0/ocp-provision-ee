#!/bin/bash

# Script to build a container image using Podman from a Dockerfile

# Configuration
IMAGE_NAME="ocp-provision-ee"
IMAGE_TAG="latest"
DOCKERFILE_PATH="${pwd}"

# Function to check if Podman is installed
check_podman() {
    if ! command -v podman &> /dev/null; then
        printf "\tError: Podman is not installed. Please install Podman and try again.\n"
        printf "\tOn RHEL-based systems, you can install it with: sudo dnf install -y podman\n"
        return 1
    fi
    printf "\tPodman version: %s\n" "$(podman --version)"
}

# Function to build the image
build_image() {
    printf "  Building container image [ %s:%s ]...\n" "${IMAGE_NAME}" "${IMAGE_TAG}"
    if ! podman build -t "${IMAGE_NAME}:${IMAGE_TAG}" "${DOCKERFILE_PATH}"; then
        printf "\tError: Failed to build the image. Check the Dockerfile and network connectivity.\n"
        return 1
    fi
    printf "Image built successfully.\n"
}

# Function to verify the image
verify_image() {
    printf "  Verifying built image\n"
    if podman images | grep -q "${IMAGE_NAME}.*${IMAGE_TAG}"; then
        printf "Image [ %s:%s ] found in local registry:\n" "${IMAGE_NAME}" "${IMAGE_TAG}"
        podman images "${IMAGE_NAME}:${IMAGE_TAG}"
    else
        printf "\tError: Image [ %s:%s ] not found.\n" "${IMAGE_NAME}" "${IMAGE_TAG}"
        return 1
    fi
}

# Function to test the image (optional)
test_image() {
    printf "  Testing the image by running a container\n"
    if ! podman run -it "${IMAGE_NAME}:${IMAGE_TAG}" -c "printf 'Available tools:\n' && ls /usr/local/bin"; then
        printf "\tWarning: Failed to run the container. Please check the image.\n"
        printf "\tCommand executed: [podman run -it \"${IMAGE_NAME}:${IMAGE_TAG}\" -c \"printf 'Available tools:\\n' && ls /usr/local/bin\\n\"]\n\n"
    else
        printf "  Container test completed.\n"
    fi
}

# Function to test utilities
test_utilities() {
    printf "  #1 Testing openshift-install\n"
    if ! podman run -it "${IMAGE_NAME}:${IMAGE_TAG}" -c "openshift-install"; then
        printf "\tWarning: Failed to run utility. Please check the image.\n"
    else
        printf "Container utility test completed.\n"
    fi
    printf "  #2 Testing ansible-vault\n"
    if ! podman run -it "${IMAGE_NAME}:${IMAGE_TAG}" -c "ansible-vault --version"; then
        printf "\tWarning: Failed to run utility. Please check the image.\n"
    else
        printf "Container utility test completed.\n"
    fi
    printf "  #3 Testing ansible-playbook\n"
    if ! podman run -it "${IMAGE_NAME}:${IMAGE_TAG}" -c "ansible-playbook --version"; then
        printf "\tWarning: Failed to run utility. Please check the image.\n"
    else
        printf "Container utility test completed.\n"
    fi
    printf "  #4 Testing kubectl\n"
    if ! podman run -it "${IMAGE_NAME}:${IMAGE_TAG}" -c "kubectl -h"; then
        printf "\tWarning: Failed to run utility. Please check the image.\n"
    else
        printf "Container utility test completed.\n"
    fi
    
    openshift-install version
    oc version --client
    kubectl version --client
}

# Main execution
printf "Starting build process for [ %s:%s ] at %s\n" "${IMAGE_NAME}" "${IMAGE_TAG}" "$(date)"

# Step 1: Check Podman
check_podman || return $?

# Step 2: Build the image
build_image || return $?

# Step 3: Verify the image
verify_image || return $?

# Step 4: Test the image (optional, can be commented out if not needed)
test_image

# Step 5: Test the utilities (optional, can be commented out if not needed)
test_utilities

printf "\nBuild process completed successfully at %s\n" "$(date)"
return 0