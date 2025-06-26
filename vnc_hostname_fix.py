#!/usr/bin/env python3

import os
import re
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# File to patch
target_file = "/app/src/magentic_ui/tools/playwright/browser/vnc_docker_playwright_browser.py"

# Read the file
with open(target_file, "r") as f:
    content = f.read()

# Find the hostname property
hostname_prop_pattern = r'@property\s+def\s+vnc_address\s*\(\s*self\s*\)\s*->.*?\s*return\s*f"http://{self\._hostname}:{self\._novnc_port}/vnc\.html"'
new_hostname_prop = '''@property
    def vnc_address(self) -> str:
        """
        Get the address of the noVNC server.
        """
        hostname = "host.docker.internal" if os.environ.get("USE_DOCKER_HOST_INTERNAL") else self._hostname
        return f"http://{hostname}:{self._novnc_port}/vnc.html"'''

# Replace the hostname property
modified_content = re.sub(hostname_prop_pattern, new_hostname_prop, content, flags=re.DOTALL)

# Write the file
with open(target_file, "w") as f:
    f.write(modified_content)
    
logger.info(f"Successfully patched {target_file}")
