#!/bin/bash

# Installation script for tikz-prerender extension
echo "Installing tikz-prerender extension..."

# Determine the project root (where prerender-tikz.sh should be)
PROJECT_ROOT=$(dirname $(dirname $(dirname "$0")))
echo "Project root: $PROJECT_ROOT"

# Make sure the prerender script is executable
if [ -f "$PROJECT_ROOT/prerender-tikz.sh" ]; then
  chmod +x "$PROJECT_ROOT/prerender-tikz.sh"
  echo "Made prerender-tikz.sh executable"
else
  echo "Warning: prerender-tikz.sh not found in project root"
fi

# Copy the tikz-html.lua filter to the extension directory if needed
if [ ! -f "tikz-html.lua" ]; then
  if [ -f "$PROJECT_ROOT/tikz-html.lua" ]; then
    cp "$PROJECT_ROOT/tikz-html.lua" .
    echo "Copied tikz-html.lua to extension directory"
  else
    echo "Error: tikz-html.lua not found!"
    exit 1
  fi
fi

# Create directories for TikZ output
mkdir -p "$PROJECT_ROOT/_tikz"
mkdir -p "$PROJECT_ROOT/_tikz_debug"
echo "Created output directories"

echo "Installation complete!"
echo 
echo "To use the tikz-prerender extension:"
echo "1. Add 'tikz_prerender: true' to your document's frontmatter"
echo "2. Make sure your _quarto.yml includes the extension in the format section:"
echo
echo "format:"
echo "  html:"
echo "    filters:"
echo "      - _extensions/tikz-prerender/prerender-hook.lua"
echo
echo "That's it! Your TikZ diagrams will now be automatically prerendered when you run 'quarto render'" 