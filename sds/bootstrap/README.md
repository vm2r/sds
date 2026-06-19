# SDS Bootstrap Helpers

Scripts do be executed in the host machone (not inside the SDS container) to start and stop the SDS container.

Main commands:

- `make sds-start`       - Start the SDS container with the latest image tag
- `make sds-start-tag`   - Start the SDS container with a specific tag
- `make sds-stop`        - Stop the SDS container
- `make sds-reset`       - Reset the SDS container (stop, delete container, delete all images and the root volume)
- `make sds-restart`     - Restart the SDS container (stop and start)
