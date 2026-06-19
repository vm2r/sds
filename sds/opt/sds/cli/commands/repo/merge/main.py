import os
import sys
import subprocess
from utils import GREEN, RED, RESET, YELLOW, BLUE, print_aligned, run_git

def run_repo_merge_main(args):
    """
    Merges the latest changes from the 'main' branch into the current branch.
    """
    # Identify current branch
    current_branch = run_git(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], "Identifying current branch")
    
    if current_branch == 'main':
        print(f"\n{YELLOW}Already on 'main' branch. Nothing to merge.{RESET}")
        return

    print(f"\n{BLUE}Merging 'main' into '{current_branch}'{RESET}")
    
    try:
        # 1. Fetch latest status from origin
        run_git(['git', 'fetch', 'origin'], "  - Fetching from origin")
        
        # 2. Update local main branch to match origin/main
        run_git(['git', 'checkout', 'main'], "  - Switching to main")
        run_git(['git', 'merge', 'origin/main', '--ff-only'], "  - Updating local main")
        
        # 3. Switch back and merge
        run_git(['git', 'checkout', current_branch], f"  - Switching back to '{current_branch}'")
        run_git(['git', 'merge', 'main'], f"  - Merging 'main' into '{current_branch}'")
            
        print(f"\n{GREEN}Repo merge main completed successfully.{RESET}")
        
    finally:
        # Robust restoration: ensure we are back on the original branch regardless of errors
        try:
            actual_branch = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], capture_output=True, text=True).stdout.strip()
            if actual_branch != current_branch:
                print_aligned(f"  - Restoring branch '{current_branch}'")
                subprocess.run(['git', 'checkout', current_branch], check=True, capture_output=True)
                print(f"{GREEN}DONE{RESET}")
        except Exception:
            # Silently fail status restoration if git itself is broken
            pass
