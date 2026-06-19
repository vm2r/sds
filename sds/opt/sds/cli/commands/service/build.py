def register(subparsers):
    build_parser = subparsers.add_parser('build', help='Build a service')
    build_parser.add_argument('service_name', help='Name of the service to build')
    build_parser.add_argument('branch_name', nargs='?', default='main', help='Branch to build from (default: main)')
    build_parser.set_defaults(func=run_service_build)
    return build_parser

def run_service_build(args):
    """
    Handles the service build command.
    """
    print("Not implemented yet.")
