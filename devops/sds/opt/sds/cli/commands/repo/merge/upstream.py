import os
import sys
import subprocess
from utils import GREEN, RED, RESET, YELLOW, BLUE, print_aligned, run_git

def run_repo_merge_upstream(args=None):
    """
    Synchronizes the local main branch with the upstream repository.
    
    This function performs the following steps:
    1. Ensures the 'upstream' remote is configured.
    2. Fetches the latest changes from upstream.
    3. Merges 'upstream/main' into the local branch (fast-forward only).
    4. Pushes the updated branch to 'origin'.
    """

    # 1. Ensures the 'upstream' remote is configured.
    print(f"\n{BLUE}Setting up GIT remotes{RESET}")
    try:
        print_aligned("  - Checking remotes")
        remotes = subprocess.run(['git', 'remote'], check=True, capture_output=True, text=True).stdout.strip()
        
        if "upstream" not in remotes.split():
            print(f"{YELLOW}NOT SET{RESET}")
            run_git(['git', 'remote', 'add', 'upstream', 'https://github.com/vm2r/sds.git'], "    - git remote add upstream https://github.com/vm2r/sds.git")
        else:
            print(f"{GREEN}ALREADY SET{RESET}")

    except Exception as e:
        print(f"{RED}ERROR{RESET}")
        print(f"\n\n{RED}ABORTING{RESET}\n\n")
        print(f"\nError checking remotes: {e}", file=sys.stderr)
        sys.exit(1)
    
    # 2. Fetches the latest changes from upstream.
    print(f"\n{BLUE}Fetching updates from upstream{RESET}")
    run_git(['git', 'fetch', 'upstream'], "  - git fetch upstream")

    # 3. Merges 'upstream/main' into the local branch (fast-forward only).
    print(f"\n{BLUE}Merging updated from upstream into local branch{RESET}")
    run_git(['git', 'merge', 'upstream/main', '--ff-only'], "  - git merge upstream/main --ff-only")

    # 4. Pushes the updated branch to 'origin'.
    print(f"\n{BLUE}Pushing updated branch to origin{RESET}")
    run_git(['git', 'push', 'origin'], "  - git push origin")

    print(f"\n{GREEN}Repo merge upstream completed successfully.{RESET}")
