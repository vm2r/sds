# SDS - Standardized Development Stack


This project uses a Standardized Development Stack (SDS) running inside a Docker container. All development tools (`pants`, `gcloud`, `isort`, etc.) must be executed inside the container.

### Running Commands
To run any command inside the environment, use the provided workflow:
- **Workflow:** [/sds-exec](file:///.agents/workflows/sds-exec.md)
- **Manual Command:** `docker exec -it sds-deepsurgery <command>`

For AI agents: Please always check `.agents/workflows/sds-exec.md` before executing terminal commands.


## How to use it?

### Initialize the environment

```bash
make sds-init
```
This will copy template files, such as `sds.conf.example`, `sds.bashrc.example`, etc., to the appropriate locations. 

You may need to edit some of these files after initialization to adjust the environment to your needs.

### Start the environment

```bash
make sds-start
```
This will build, register and start the SDS image locally. YOU must have Docker Desktop installed and running.

### Stop the environment

```bash
make sds-stop
```
This will stop the SDS container, but not delete it

### Restart the environment

```bash
make sds-restart
```
This will stop the SDS container and start it again.

### Reset the environment

```bash
make sds-reset
```
This will stop the SDS container, delete it, delete the image and delete the root volume.

### Print help

```bash
make help
```
