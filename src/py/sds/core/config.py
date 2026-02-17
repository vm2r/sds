import importlib.resources
import os
from importlib.resources.abc import Traversable
from typing import (
    Any,
    Dict,
)

import yaml


class Config:
    _config_instance: Dict[str, Any] | None = None

    # The package name of the Mutua service that is currently being executed
    _this_service_package: str | None = None

    # The folder path of the Mutua service that is currently being executed
    _service_folder_path: Traversable | None = None

    @classmethod
    def _get_instance(cls) -> Dict[str, Any]:
        if cls._config_instance is None:
            raise ValueError("Config has not been initialized. Must call 'Config.initialize()'.")
        return cls._config_instance

    @classmethod
    def get(cls, key_path: str, default_value: Any = None) -> str:
        """Retrieves a value from a nested dictionary based on a path of keys.

        Args:
            key_path (str): A string representing the path to the desired value,
                            with keys separated by dots (e.g., "a.b.c").

        Returns:
            The value at the specified path, if found, or the default value otherwise.
        """
        key_path_parts = key_path.split(".")
        current_level = cls._get_instance()

        for key_part in key_path_parts:
            if isinstance(current_level, dict) and key_part in current_level:
                current_level = current_level[key_part]
            else:
                return default_value  # Invalid path

        return current_level

    @classmethod
    def get_service_root_folder_path(cls) -> Traversable:
        """Get the service root folder path (the python packages root folder)"""

        # Find the Mutua package folder
        mutua_package_folder: Traversable = importlib.resources.files("mutua")

        # return the root package folder (the folder containing the python packages)
        return mutua_package_folder.joinpath("..")

    @classmethod
    def initialize(cls, config_file_package: str) -> None:
        """Initialize the Config singleton with configuration from a YAML content.

        This method loads configuration from either a config.yaml file in the package
        directory or from an environment variable. When deployed, the environment variable
        is mapped to a Secret in the Cloud Run service.

        It then parses the YAML content
        and stores it in the singleton instance.

        Args:
            config_file_package: The package name where the config.yaml file is located
                                or the suffix for the environment variable name.

        Raises:
            ValueError: If no configuration is found or if the YAML content cannot be parsed.
        """

        CONFIG_FILENAME: str = "config.yaml"
        CONFIG_ENVVAR: str = "CONFIG_YAML"

        def get_content_from_config_file() -> str | None:
            """Retrieves the content of the config.yaml file from the package."""
            nonlocal CONFIG_FILENAME

            config_file_path = cls._service_folder_path.joinpath(CONFIG_FILENAME)

            if os.path.exists(config_file_path):
                with open(config_file_path, "r") as file:
                    return file.read()
            else:
                return None

        def get_content_from_envvar() -> str | None:
            """Retrieves the configuration content from the environment variable."""
            return os.environ.get(CONFIG_ENVVAR, None)

        #
        # Start Config initialization
        #

        # Get the absolute path of the Mutua service folder
        cls._this_service_package = config_file_package
        cls._service_folder_path: Traversable = importlib.resources.files(cls._this_service_package)

        # Look for the config YAML content (config.yaml file or environment variable)
        config_content: str | None = get_content_from_config_file()

        # Try to find the config YAML content from file or environment variable
        if config_content is None:
            config_content = get_content_from_envvar()

        if config_content is None:
            raise RuntimeError(
                f"FATAL|CONFIG_NOT_FOUND|"
                f"Missing config file {CONFIG_FILENAME} or environment variable: {CONFIG_ENVVAR}"
            )

        # Config content was found. Try to load it.
        try:
            config_dict = yaml.safe_load(config_content)
        except yaml.YAMLError as e:
            raise RuntimeError(f"FATAL|CONFIG_PARSE_ERROR|{str(e)}")

        cls._config_instance = config_dict
