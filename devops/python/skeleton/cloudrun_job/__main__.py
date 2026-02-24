#
# THIS FILE IS PRODUCED BY 'sds module create'
# DON'T CHANGE THIS FILE UNLESS YOU KNOW WHAT YOU'RE DOING
#

from mutua.utils import (
    Config,
    Logger,
)

this_package = globals()["__package__"]

Config.initialize(this_package)
Logger.initialize(this_package)


def entrypoint() -> str:
    status_code: str = "OK"
    try:
        Logger.sys("START")
        from .main import main

        main()
    except Exception as e:
        import traceback

        Logger.error(f"ERROR:Failed with {str(e)}")
        Logger.error(traceback.format_exc())
        status_code = "ERR"
    finally:
        Logger.sys("FINISH", status_code=status_code)

    return status_code


if __name__ == "__main__":
    status_code = entrypoint()
    exit(0) if status_code == "OK" else exit(1)
