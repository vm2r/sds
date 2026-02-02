from . import merge as merge_cmd

def register(subparsers):
    repo_parser = subparsers.add_parser('repo', help='Repository operations')
    repo_subparsers = repo_parser.add_subparsers(dest='subcommand', help='Repo subcommands')
    
    # Register sub-subcommands
    merge_cmd.register(repo_subparsers)
    
    return repo_parser
