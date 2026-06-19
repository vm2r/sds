import subprocess
import os
import sys

# ANSI Color Escape Codes
GREEN = '\033[92m'
RED = '\033[91m'
BLUE = '\033[94m'
YELLOW = '\033[93m'
RESET = '\033[0m'

def print_aligned(text, width=60):
    """
    Prints text with trailing dots for alignment, ensuring at least 3 dots.
    """
    dots = max(3, width - len(text))
    print(f"{text}{'.' * dots} ", end='', flush=True)

def run_git(cmd, description):
    """
    Executes a git command with aligned terminal output and color-coded results.
    """
    print_aligned(description)
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(f"{GREEN}DONE{RESET}")
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"{RED}ERROR{RESET}")
        print(f"\nError Details:\n{e.stderr}", file=sys.stderr)
        sys.exit(1)
