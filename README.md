# Ansible EE + OpenShift 4.18 Installer Container

This project provides a **container image** based on Red Hat Ansible Automation Platform 25 (RHEL9) that includes:

- **Ansible EE** (Execution Environment)
- **OpenShift Installer 4.18** (`openshift-install`)
- **OpenShift CLI (`oc`)`** and **`kubectl`**
- Minimal image size using **multi-stage build** and `microdnf`

The container is designed for **interactive OpenShift automation** and cluster creation.

---

## Quick Start Diagram
Host Directory (~/ocp-workdir)
│
▼
┌───────────────────────────┐
│ Docker Container │
│ ┌─────────────────────┐ │
│ │ /usr/local/bin │ │
│ │ ├─ openshift-install │ │
│ │ ├─ oc │ │
│ │ └─ kubectl │ │
│ └─────────────────────┘ │
│ /workdir (mounted) │
└───────────────────────────┘
│
▼
OpenShift Cluster


- The host folder `~/ocp-workdir` is mounted into `/workdir` in the container.
- All generated files (install configs, manifests, auth credentials) are persisted on the host.

---

## Dockerfile Overview

The Dockerfile uses a **multi-stage build**:

1. **Builder stage**:
   - Installs temporary utilities (`curl`, `tar`)
   - Downloads and extracts OpenShift binaries
   - Keeps binaries in `/tmp` for copying

2. **Final stage**:
   - Starts from the same Ansible EE base
   - Copies only `openshift-install`, `oc`, and `kubectl` from the builder
   - No temporary packages or tarballs remain
   - Minimal layers, smaller image size

---

## Build Instructions

```bash
# Build the container
docker build -t aap-ee-ocp4.18-optimized .

# Run the container interactively
```bash
# Create a workspace directory on your host
mkdir -p ~/ocp-workdir

# Run the container and mount the workspace
docker run --rm -it \
  -v ~/ocp-workdir:/workdir \
  aap-ee-ocp4.18-optimized
```
# Usage Inside the Container

1. Navigate to the workspace:
```bash
cd /workdir
```

2. Optional: Remove the mount test file before starting the installer:
```bash
rm -f /workdir/testfile
```

3. Run OpenShift cluster creation:
```bash
openshift-install create cluster --dir=/workdir
```

4. Verify versions:
```bash
openshift-install version
oc version --client
kubectl version --client
ansible --version
ansible-playbook --version
ansible-vault --version
```

# Optional Convienience

useCreate a shell alias on your host for easier container startup:
```bash
alias ocp-container='docker run --rm -it -v ~/ocp-workdir:/workdir aap-ee-ocp4.18-optimized'
````

Then you can simply run:
```bash
ocp-container
cd /workdir
openshift-install create cluster --dir=/workdir
```

# Troubleshooting Tips

* Permission issues on mounted workspace:
Make sure your host directory is writable by your user. Use chmod -R 755 ~/ocp-workdir if necessary.

* Network connectivity issues:
OpenShift installer downloads images during cluster creation. Ensure the container has network access.

* Insufficient memory:
OpenShift clusters require at least 16 GB RAM for a full install. Increase Docker/Podman memory allocation if using local cluster creation.

* Installer fails with proxy settings:
Set environment variables inside the container if behind a proxy:

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=127.0.0.1,localhost,*.example.com
```

* openshift-install not found:
Ensure the container is built with the multi-stage Dockerfile so that /usr/local/bin/openshift-install exists.

* Updating to a new OpenShift version:
Change the OCP_VERSION build argument in the Dockerfile and rebuild the image.