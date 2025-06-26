#!/usr/bin/env python3

# This script patches the VNC browser hostname to use host.docker.internal
# to make VNC accessible from the host machine

import os
import sys

# Check if MAGENTIC_UI_PATH env var is set
if 'MAGENTIC_UI_PATH' in os.environ:
    vnc_browser_file = os.path.join(os.environ['MAGENTIC_UI_PATH'], 'src/magentic_ui/tools/playwright/browser/vnc_docker_playwright_browser.py')
else:
    # Default path in Docker container
    vnc_browser_file = '/app/src/magentic_ui/tools/playwright/browser/vnc_docker_playwright_browser.py'

print(f"Patching VNC browser hostname in: {vnc_browser_file}")

if not os.path.exists(vnc_browser_file):
    print(f"Error: File not found: {vnc_browser_file}")
    sys.exit(1)

with open(vnc_browser_file, 'r') as f:
    content = f.read()

# Replace the hostname with host.docker.internal
if 'def vnc_address' in content:
    modified_content = content.replace(
        'def vnc_address(self) -> str:',
        'def original_vnc_address(self) -> str:\n        pass\n\n    @property\n    def vnc_address(self) -> str:'
    )
    
    # Add the hostname override
    modified_content = modified_content.replace(
        'Get the address of the noVNC server.\n        """',
        'Get the address of the noVNC server.\n        """\n        import os\n        hostname = "host.docker.internal" if os.environ.get("USE_DOCKER_HOST_INTERNAL") else self._hostname'
    )
    
    with open(vnc_browser_file, 'w') as f:
        f.write(modified_content)
        
    print("VNC browser hostname patched successfully!")
else:
    print("Error: Could not find 'def vnc_address' in the file")
    sys.exit(1)
