def register(subparsers):
    list_parser = subparsers.add_parser('list', help='List all services')
    list_parser.set_defaults(func=run_service_list)
    return list_parser

def run_service_list(args):
    """
    Shows the list of available services.
    """
    print("Not implemented yet.")
