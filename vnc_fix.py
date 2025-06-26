#!/usr/bin/env python3

# This script patches the VNC browser script to fix the indentation error

import os
import sys

VNC_FILE = "magentic-ui/src/magentic_ui/tools/playwright/browser/vnc_docker_playwright_browser.py"

if not os.path.exists(VNC_FILE):
    print(f"Error: File not found: {VNC_FILE}")
    sys.exit(1)

with open(VNC_FILE, "r") as f:
    lines = f.readlines()

# Find the problematic function
problem_line = -1
for i, line in enumerate(lines):
    if "@property" in line and i > 0 and "def" in lines[i-1] and not lines[i-1].strip().endswith(":"):
        problem_line = i-1
        print(f"Found problem at line {problem_line+1}: {lines[problem_line].strip()}")
        break

if problem_line >= 0:
    # Fix the problem by adding missing pass statement
    if "def" in lines[problem_line] and not lines[problem_line].strip().endswith(":"):
        lines[problem_line] = lines[problem_line].rstrip() + ":\n"
        lines.insert(problem_line + 1, "        pass\n")
        print("Added missing colon and pass statement")
    
    with open(VNC_FILE, "w") as f:
        f.writelines(lines)
    print("Fixed the VNC browser code!")
else:
    print("Couldn't find the problematic line")
