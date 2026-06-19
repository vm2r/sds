def register(subparsers):
    version_parser = subparsers.add_parser('version', help='Shows the version of the environment')
    version_parser.set_defaults(func=run_version)
    return version_parser

def run_version(args):
    """
    Shows the version of the environment.
    """
    print("Not implemented yet.")
