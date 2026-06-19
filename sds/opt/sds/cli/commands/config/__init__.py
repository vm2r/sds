from .edit import run_config_edit

def register(subparsers):
    config_parser = subparsers.add_parser('config', help='Configuration management')
    config_subparsers = config_parser.add_subparsers(dest='config_subcommand', help='Config subcommands')
    
    # sds config edit
    edit_parser = config_subparsers.add_parser('edit', help='Edit sds.conf')
    edit_parser.set_defaults(func=run_config_edit)
    
    return config_parser
