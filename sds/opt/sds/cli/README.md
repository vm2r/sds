# SDS CLI Tool

The SDS CLI tool is a modular command-line interface designed to manage development environments and repository operations. It provides a consistent way to interact with various project components, including version tracking, environment status checks, and streamlined workflows for repository synchronization and service management.

## DESIGN PHILOSOPHY
### Zero External Dependencies
The SDS CLI is built using **only the Python 3 Standard Library**. 
- **No `pip install` required**: Works out-of-the-box on any system with Python 3.
- **Portability**: Relies only on system-level tools like `git` and `vi`.
- **Security & Speed**: Minimal footprint ensures fast execution and reduces the attack surface from third-party packages.

## SYNOPSIS
`sds [COMMAND] [SUBCOMMAND] [ARGUMENTS]`

## COMMANDS

### `version`
Shows the version of the environment.

### `status`
Shows the environment status.

### `repo`
Repository operations.

- **`merge upstream`**
  Merges branches from the `upstream` repository.
- **`merge main`**
  Merges branches from the local `main` branch.

### `service`
Service operations.

- **`list`**
  List all available services.
- **`build <service_name> [branch_name]`**
  Build a specific service from a branch (defaults to `main`).
- **`deploy <service_name> <source_tag> <destination_env>`**
  Deploy a service version to a target environment (e.g., staging, production).

### `config`
Configuration management.

- **`edit`**
  Edit the `sds.conf` configuration file using `vi`.

## OPTIONS
- **`-h`, `--help`**
  Show help message and exit.
