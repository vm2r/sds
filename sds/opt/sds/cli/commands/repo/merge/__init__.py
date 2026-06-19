from .main import run_repo_merge_main
from .upstream import run_repo_merge_upstream

def register(subparsers):
    merge_parser = subparsers.add_parser('merge', help='Merges branches')
    merge_subparsers = merge_parser.add_subparsers(dest='merge_target', help='Merge targets')
    
    # sds repo merge upstream
    upstream_parser = merge_subparsers.add_parser('upstream', help='Merge from upstream')
    upstream_parser.set_defaults(func=run_repo_merge_upstream)

    # sds repo merge main
    main_parser = merge_subparsers.add_parser('main', help='Merge from main')
    main_parser.set_defaults(func=run_repo_merge_main)
    
    return merge_parser
