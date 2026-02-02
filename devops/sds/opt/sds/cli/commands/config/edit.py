import os
import sys
import subprocess
from utils import BLUE, RESET, run_git, GREEN, RED

def run_config_edit(args):
    """
    Identifies the sds.conf file path and opens it in vi.
    """
    # Identify the repository root using git
    repo_root = run_git(['git', 'rev-parse', '--show-toplevel'], "Identifying repository root")
    
    # Configuration file is always at [REPO_ROOT]/devops/sds/etc/sds.conf
    config_path = os.path.join(repo_root, "devops/sds/etc/sds.conf")
    
    print(f"\n{BLUE}SDS Configuration File{RESET}")
    print(f"Path: {config_path}\n")
    
    if not os.path.exists(config_path):
        print(f"Error: Configuration file not found at {config_path}", file=sys.stderr)
        sys.exit(1)
        
    try:
        # Launch vi to edit the file
        subprocess.run(['vi', config_path], check=True)
        
        # Validation
        print(f"\n{BLUE}Validating configuration{RESET}")
        
        sds_root = os.path.join(repo_root, "devops/sds")
        validation_script = os.path.join(sds_root, "bootstrap/sds-load-config.sh")
        
        # Prepare environment for the validation script
        env = os.environ.copy()
        env["SDS_ROOT_IN_HOST"] = sds_root
        # Add the SDS utilities folder to the PATH so sds-load-config.sh can find printf_color
        sds_utils_path = os.path.join(sds_root, "opt/sds")
        env["PATH"] = f"{env.get('PATH', '')}:{sds_utils_path}"
        
        result = subprocess.run(['bash', validation_script], env=env, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"  - sds-load-config.sh....................... {GREEN}PASSED{RESET}")
            print(f"\n{GREEN}Configuration is valid.{RESET}")
        else:
            print(f"  - sds-load-config.sh....................... {RED}FAILED{RESET}")
            print(f"\n{RED}Validation Error:{RESET}")
            print(result.stdout)
            print(result.stderr)
            sys.exit(1)
            
    except subprocess.CalledProcessError:
        print(f"\n{YELLOW}Edit cancelled or vi exited with error.{RESET}")
    except Exception as e:
        print(f"Error during validation: {e}", file=sys.stderr)
        sys.exit(1)
