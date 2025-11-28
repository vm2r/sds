# SDS - Standardized Development Stack

SDS is a Docker-based development environment designed to provide a consistent, pre-configured toolset for developers. It eliminates the "it works on my machine" problem by ensuring everyone uses the same versions of languages, tools, and system dependencies.

## 🚀 Quick Start

To start the development environment locally:

```bash
make sds-local
```

This command will:
1. Build the Docker image locally (if needed).
2. Start the container.
3. Drop you into a `bash` shell inside the standardized environment.

To stop the environment:

```bash
make rest
```

## 🛠️ Included Tools

The SDS image comes pre-loaded with a comprehensive suite of development tools:

### Languages
- **Python**: v3.12 (via `pyenv`)
- **Node.js**: v24.7.0 (via `nvm`)

### Build & Infrastructure
- **Pants**: Build system (v2.23.0)
- **Pulumi**: Infrastructure as Code (latest)
- **Docker**: For container management

### Cloud & CLI Tools
- **Google Cloud SDK**: `gcloud` CLI (optimized for size)
- **GCS FUSE**: Mount Google Cloud Storage buckets locally
- **Dataform CLI**: For managing data pipelines
- **GitHub CLI**: `gh`

### Utilities
- **Editors**: `vim`, `nano`
- **Network**: `curl`, `wget`, `netcat`, `dnsutils`, `ping`, `telnet`
- **System**: `htop`, `procps`, `lsb-release`
- **Data**: `jq`, `yq`, `postgresql-client`
- **Shell**: `zsh`, `zplug`

## 📂 Repository Structure

- **`sds/`**: Core SDS configuration and scripts.
    - **`bootstrap/`**: Startup and shutdown scripts.
    - **`etc/`**: Configuration files.
    - **`opt/`**: Optional utilities.
- **`image-builder/`**: Dockerfile and build scripts for creating the SDS image.
- **`Makefile`**: Entry point for managing the environment.

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) (if available) for details on our code of conduct, and the process for submitting pull requests.

### Pull Requests
All PRs must follow the template and require review from code owners.
