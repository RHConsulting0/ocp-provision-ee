


[Ansible Automation Platform supported execution environment - containerfile](https://catalog.redhat.com/en/software/containers/ansible-automation-platform-25/ee-supported-rhel9/650a56807ab682340da38ad5#containerfile)







```dockerfile
ARG REMOTE_SOURCES
ARG REMOTE_SOURCES_DIR

FROM ansible-automation-platform-25-ee-minimal-rhel9:latest AS galaxy
# =============================================================================
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS=

ADD _build /build
WORKDIR /build

RUN ansible-galaxy role install -r requirements.yml --roles-path /usr/share/ansible/roles
RUN ansible-galaxy collection install $ANSIBLE_GALAXY_CLI_COLLECTION_OPTS -r requirements.yml --collections-path /usr/share/ansible/collections

# NOTE(pabelanger): Install extra collections for automation controller
RUN ansible-galaxy collection install $ANSIBLE_GALAXY_CLI_COLLECTION_OPTS -r controller-requirements.yml --collections-path /usr/share/automation-controller/collections

FROM ansible-automation-platform-25-ansible-builder-rhel9:latest AS builder
# =============================================================================

# NOTE(pabelanger): Copy in data from https://cachito.engineering.redhat.com
# https://source.redhat.com/groups/public/container-build-system/container_build_system_wiki/containers_from_source_multistage_builds_in_osbs#jive_content_id_Cachito_Integration_for_pip
COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR

ENV SUDS_PACKAGE=suds

COPY --from=galaxy /usr/share/ansible/collections /usr/share/ansible/collections
COPY --from=galaxy /usr/share/automation-controller/collections /usr/share/ansible/collections
ADD _build/bindep.txt bindep.txt
RUN ansible-builder introspect --sanitize --user-bindep=bindep.txt --write-bindep=/tmp/src/bindep.txt --write-pip=/tmp/src/requirements.txt

# HACK THE GIBSON!! - https://github.com/ansible/ansible-builder/issues/207
# NOTE(pabelanger): We really need a denylist for bindep.txt, until we update
# collections upstream manually remove python38 RPMs.
RUN sed -i.orig '/python38.*/d;/python39.*/d;/python3-.*/d;/dnf/d' /tmp/src/bindep.txt && \
    sed -i.orig '/vsphere-automation-sdk-python/d' /tmp/src/requirements.txt && \
    sed -i.orig '/sys_platform == "linux"/d' /tmp/src/requirements.txt && \
    sed -i.orig '/systemd/d;/psycopg\[binary,pool\]/c\psycopg' /tmp/src/requirements.txt

ADD _build/build-requirements.txt /tmp/src/build-requirements.txt
# NOTE(pabelanger): Combined both requirements files for upper-constraints.txt
RUN cd $REMOTE_SOURCES_DIR/cachito/app/ee-supported \
  && cat build-requirements.txt requirements.txt > /tmp/src/upper-constraints.txt

# NOTE(pabelanger): Disable build isolation for pip3. This means we can use
# existing python RPMs for build dependencies over adding them to cachito.
ENV PIP_OPTS=--no-build-isolation
ADD _build/maturin-rust-vendor.tar.bz2 _build/pendulum-rust-vendor.tar.bz2 .
ADD _build/config.toml /root/.cargo/
COPY assemble /usr/local/bin/assemble
RUN source $REMOTE_SOURCES_DIR/cachito/cachito.env && \
    assemble

COPY _library/vsphere-automation-sdk-python-7.0.3.2.tar.gz /output
RUN source $REMOTE_SOURCES_DIR/cachito/cachito.env && \
    pip3 install $PIP_OPTS --cache-dir=/output/wheels file:///output/vsphere-automation-sdk-python-7.0.3.2.tar.gz

FROM ansible-automation-platform-25-ee-minimal-rhel9:latest
# =============================================================================

COPY $REMOTE_SOURCES $REMOTE_SOURCES_DIR

COPY --from=galaxy /usr/share/ansible /usr/share/ansible
COPY --from=galaxy /usr/share/automation-controller /usr/share/automation-controller
COPY --from=builder /output/ /output

RUN source $REMOTE_SOURCES_DIR/cachito/cachito.env \
  && /output/install-from-bindep \
  && pip3 install --cache-dir=/output/wheels file:///output/vsphere-automation-sdk-python-7.0.3.2.tar.gz \
  && rm -rf /output/ $REMOTE_SOURCES_DIR

ENV DESCRIPTION="Red Hat Ansible Automation Platform Supported Execution Environment" \
    container=oci

LABEL com.redhat.component="ee-supported-container" \
      name="ansible-automation-platform-25/ee-supported-rhel9" \
      version="1.0.0" \
      summary="${DESCRIPTION}" \
      io.openshift.expose-services="" \
      io.openshift.tags="automation,ansible" \
      io.k8s.display-name="ee-supported-rhel9" \
      maintainer="Ansible Automation Platform Productization Team" \
      description="${DESCRIPTION}"
```






ansible-playbook -i /runner/project/inventory.yml \
    -e @/runner/project/group_vars/cluster/lab/all.yaml \
    -e @/runner/project/group_vars/env/lab/default-vault.yaml \
    -e @/runner/project/group_vars/env/lab/all.yaml \
    -e @/runner/all-clusters-resources/pull-secret.json \
    -e @/runner/project/secrets/lab/pull-secret.json \
    --vault-password-file=/runner/all-clusters-resources/vault-password.txt \
    /runner/project/prep_cluster_install.yaml -vvvv