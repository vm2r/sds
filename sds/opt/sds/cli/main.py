import argparse
import sys
from commands import version, status, repo, service, config

def get_deepest_parser(parser, args):
    """
    Recursively finds the deepest subparser reached based on the arguments provided.
    """
    # Look for subparser actions in the current parser
    for action in parser._actions:
        if isinstance(action, argparse._SubParsersAction):
            # Check if the dest for this subparser is present in args
            subcommand_name = getattr(args, action.dest, None)
            if subcommand_name and subcommand_name in action.choices:
                # Recursively check the chosen sub-parser
                return get_deepest_parser(action.choices[subcommand_name], args)
    return parser

def main():
    parser = argparse.ArgumentParser(
        prog='sds',
        description='SDS CLI Tool - Managed environment and repository operations'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # Register commands
    version.register(subparsers)
    status.register(subparsers)
    repo.register(subparsers)
    service.register(subparsers)
    config.register(subparsers)

    args = parser.parse_args()

    if hasattr(args, 'func'):
        try:
            args.func(args)
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        # If no specific function is assigned, it means the command is incomplete.
        # Use our recursive helper to find the deepest context reached.
        deepest_parser = get_deepest_parser(parser, args)
        deepest_parser.print_help()

if __name__ == '__main__':
    main()
