# Stage 1: Builder stage using UBI minimal (curl/tar installed)
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

ARG OCP_VERSION=4.18.23
ARG ARCH=amd64

# URLs for installer and client
ARG INSTALLER_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz
ARG CLIENT_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${ARCH}-rhel9.tar.gz

# Install temporary tools and download/extract binaries
RUN microdnf -y update \
    && microdnf -y install tar gzip \
    && curl -fSL "${INSTALLER_URL}" -o /tmp/openshift-install.tar.gz \
    && curl -fSL "${CLIENT_URL}" -o /tmp/openshift-client.tar.gz \
    && tar -C /tmp -xzf /tmp/openshift-install.tar.gz openshift-install \
    && tar -C /tmp -xzf /tmp/openshift-client.tar.gz oc kubectl \
    && chmod +x /tmp/openshift-install /tmp/oc /tmp/kubectl \
    && microdnf remove -y tar gzip \
    && microdnf clean all

# Stage 2: Final image using Ansible EE
FROM registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest

# Copy OpenShift binaries from builder
COPY --from=builder /tmp/openshift-install /usr/local/bin/openshift-install
COPY --from=builder /tmp/oc /usr/local/bin/oc
COPY --from=builder /tmp/kubectl /usr/local/bin/kubectl

# Ensure binaries are executable
RUN chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc /usr/local/bin/kubectl

# Verify installation
RUN openshift-install version && \
    oc version --client && \
    kubectl version --client && \
    ansible --version && \
    ansible-playbook --version && \
    ansible-vault --version

RUN mkdir -p /runner/project/install-dir

# Set entrypoint to bash
ENTRYPOINT ["/usr/bin/bash"]

