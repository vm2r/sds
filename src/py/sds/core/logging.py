import inspect
import json
import logging
import sys
from enum import Enum
from typing import (
    Any,
    Callable,
    Dict,
    List,
    Optional,
)

from google.cloud.logging.handlers import StructuredLogHandler
from google.cloud.logging_v2.handlers import setup_logging

from sds.utils.core.config import Config


def convert_bytes(obj: Any) -> dict | list | str:
    if isinstance(obj, dict):
        return {k: convert_bytes(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_bytes(i) for i in obj]
    elif isinstance(obj, bytes):
        return obj.decode("utf-8", errors="replace")
    else:
        return str(obj)


class LogEnvironment(Enum):
    """The destination of the log entry."""

    LOCAL = "LOCAL"
    GCP = "GCP"


class LogType(Enum):
    """The type of log entry.

    It maps the standard logging levels (info, warning, error, etc...)
    """

    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    EXCEPTION = "EXCEPTION"
    FATAL = "FATAL"
    DEBUG = "DEBUG"
    SYS = "SYS"
    PERF = "PERF"
    API_REQUEST = "API_REQUEST"


class Logger:

    # Attributes set by the initialize() class method
    _app_package_name: Optional[str] = None
    _logging_writer: Optional[Callable] = None
    _logging_functions: Optional[Dict[LogType, Callable]] = None

    @classmethod
    def _get_app_package_name(cls) -> str:
        """Getter method for attribute _app_package_name.

        We use this getter to check if the Logger class has been initialized.
        """
        if cls._app_package_name is None:
            raise ValueError("Logger has not been initialized. Must call 'Logger.initialize()'.")
        return cls._app_package_name

    @classmethod
    def initialize(cls, package_name: str, log_level=logging.INFO):
        """Prepare the Logger as a Singleton."""
        cls._app_package_name = package_name

        log_environment = LogEnvironment[Config.get("logging.env", "local").upper()]

        if log_environment == LogEnvironment.GCP:
            # Initialize the GCP specific logging client (logs JSON objects instead of strings)
            handler = StructuredLogHandler()
            setup_logging(handler)

        # Map the functions that actually write the log to the environment type
        log_writers: Dict[LogEnvironment, Callable] = {
            LogEnvironment.LOCAL: cls._create_local_log_entry,
            LogEnvironment.GCP: cls._create_gcp_log_entry,
        }

        cls._logging_writer = log_writers[log_environment]

        logging.basicConfig(
            format=Config.get("logging.format", "%(message)"),
            datefmt=Config.get("logging.datefmt", "%(asctime)s"),
            level=Config.get("logging.level", log_level),
        )
        logger_instance: logging.Logger = logging.getLogger(package_name)

        # Maps the log type to the corresponding logging function
        cls._logging_functions = {
            LogType.INFO: logger_instance.info,
            LogType.WARNING: logger_instance.warning,
            LogType.ERROR: logger_instance.error,
            LogType.FATAL: logger_instance.fatal,
            LogType.DEBUG: logger_instance.debug,
            LogType.SYS: logger_instance.info,
            LogType.PERF: logger_instance.info,
            LogType.API_REQUEST: logger_instance.info,
            LogType.EXCEPTION: logger_instance.exception,
        }

    @classmethod
    def debug(cls, message: str, **kwargs):
        cls._log(log_type=LogType.DEBUG, message=message, extra_attributes=kwargs)

    @classmethod
    def info(cls, message: str, **kwargs):
        cls._log(log_type=LogType.INFO, message=message, extra_attributes=kwargs)

    @classmethod
    def warning(cls, message: str, **kwargs):
        """Prepares a log entry to record a warning."""
        cls._log(
            log_type=LogType.WARNING,
            message=message,
            extra_attributes=kwargs,
        )

    @classmethod
    def error(cls, message: str, **kwargs):
        """Prepares a log entry to record an error."""
        cls._log(
            log_type=LogType.ERROR,
            message=message,
            extra_attributes=kwargs,
        )

    @classmethod
    def exception(cls, message: str, **kwargs):
        """Prepares a log entry to record an error."""
        cls._log(
            log_type=LogType.EXCEPTION,
            message=message,
            extra_attributes=kwargs,
        )

    @classmethod
    def fatal(cls, message: str, **kwargs):
        """Prepares a log entry to record a fatal error."""
        cls._log(
            log_type=LogType.FATAL,
            message=message,
            extra_attributes=kwargs,
        )

    @classmethod
    def sys(cls, message: str, **kwargs):
        """Prepares a log entry to record a system message (start, finish, etc..)"""
        cls._log(log_type=LogType.SYS, message=message, extra_attributes=kwargs)

    @classmethod
    def api_request(cls, route, payload, response, **kwargs):
        """Prepares a log entry to record an API request."""
        payload = {
            "by": Config.get("service.name", None),
            "method": kwargs.get("method", None),
            "route": route,
            "payload": payload,
            "benchmark": kwargs.pop("benchmark", None),
            "response": {
                "payload": response,
                "status_code": kwargs.get("status_code", None),
            },
            "tracking_id": kwargs.get("tracking_id", None),
        }
        cls._log(
            log_type=LogType.API_REQUEST,
            message=route,
            extra_attributes=payload,
        )

    @classmethod
    def perf(cls, metric_key: str, metric_value: Any, metric_unit: str = "", **kwargs):
        """Prepares a log entry to record a performance metric, like elapsed time, counters, etc...

        :param str metric_key: The name of the metric lile "FETCH_TIME", "RETRY_COUNT", etc...
        :param Any metric_value: The value of the metric, lile 1, 2, 5.6, "OK", "FAIL", etc...
        :param str metric_unit: The unit, if applicable
        :param dict kwargs: additional fields to add to the metric entry
        """
        message = f"{metric_key}|{metric_value}" if metric_unit == "" else f"{metric_key}|{metric_value}|{metric_unit}"
        cls._log(
            log_type=LogType.PERF,
            message=message,
            extra_attributes=kwargs,
        )

    @classmethod
    def _log(cls, log_type: LogType, message: str, extra_attributes: dict) -> None:
        """Add log environmental entries to log.

        :param int log_type: The type of log entry to be added
        :param str message: The log message to be added
        :param dict extra_attributes: A dict with the data to store in the log
        """

        log_entry = {
            "type": log_type.name,
            "message": message,
            "app": cls._get_app_package_name(),
            "at": cls.caller_name(),
        }

        if len(extra_attributes) > 0:
            log_entry["extra"] = extra_attributes

        cls._logging_writer(log_type, log_entry)

    @classmethod
    def _create_gcp_log_entry(cls, log_type: LogType, payload: dict) -> None:
        """Records a log entry in GCP Cloud Logging."""
        clean_payload = convert_bytes(payload)
        log_message = json.dumps(clean_payload)

        # TODO (mauro): make GCP log entry be a true JSON for Cloud Logging querying
        cls._logging_functions[log_type](log_message)

    @classmethod
    def _create_local_log_entry(cls, log_type: LogType, payload: dict) -> None:
        """Records a log entry in the local console."""
        payload_copy: dict = dict(payload)
        log_message: str = ""

        # Log entry prefix with predefined fields
#        entry_field_names = ["app", "type", "at", "message"]
        entry_field_names = ["type", "at", "message"]
        for entry_field in entry_field_names:
            log_message += f"{payload_copy[entry_field]}|"
            del payload_copy[entry_field]

        # Attach other attributes
        for attribute_name, attribute_value in payload_copy.items():
            log_message += f"{attribute_name}:{attribute_value}|"

        cls._logging_functions[log_type](log_message)

    @classmethod
    def caller_name(cls, skip: int = 2):
        """Get a name of a caller in the format module.class.method.

        `skip` specifies how many levels of stack to skip while getting caller
        name. skip=1 means "who calls me", skip=2 "who calls my caller" etc.

        An empty string is returned if skipped levels exceed stack height
        """

        def stack_(frame):
            framelist = []
            while frame:
                framelist.append(frame)
                frame = frame.f_back
            return framelist

        stack = stack_(sys._getframe(1))
        start = 0 + skip
        if len(stack) < start + 1:
            return ""

        parentframe = stack[start]

        name: List[str] = []
        module = inspect.getmodule(parentframe)
        if module is not None:
            # `modname` can be None when frame is executed directly in console

            module_name = module.__name__ if module.__name__ != "__main__" else cls._get_app_package_name()
            name.append(module_name)

        # detect classname
        if "self" in parentframe.f_locals:
            name.append(parentframe.f_locals["self"].__class__.__name__)

        codename = parentframe.f_code.co_name
        if codename != "<module>":  # top level usually
            name.append(codename)  # function or a method

        del parentframe
        return ".".join(name)
