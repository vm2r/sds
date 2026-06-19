def register(subparsers):
    status_parser = subparsers.add_parser('status', help='Shows the environment status')
    status_parser.set_defaults(func=run_status)
    return status_parser

def run_status(args):
    """
    Shows the environment status.
    """
    print("Not implemented yet.")
