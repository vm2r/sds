from . import list as list_cmd
from . import build as build_cmd
from . import deploy as deploy_cmd

def register(subparsers):
    service_parser = subparsers.add_parser('service', help='Service operations')
    service_subparsers = service_parser.add_subparsers(dest='subcommand', help='Service subcommands')

    # Register sub-subcommands
    list_cmd.register(service_subparsers)
    build_cmd.register(service_subparsers)
    deploy_cmd.register(service_subparsers)

    return service_parser
