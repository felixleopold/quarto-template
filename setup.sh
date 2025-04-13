#!/bin/bash

# Quarto TikZ and Mermaid Template Setup Script
# This script sets up the template in the current directory or a specified directory

set -e  # Exit on error

# Default target directory is the current directory
TARGET_DIR="."
REPO_URL="https://github.com/felixleopold/quarto-template.git"
FORCE_INSTALL=false
SKIP_DEPENDENCIES=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -f|--force)
      FORCE_INSTALL=true
      shift
      ;;
    --skip-deps)
      SKIP_DEPENDENCIES=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo
      echo "Options:"
      echo "  -d, --dir DIR     Install template to DIR (default: current directory)"
      echo "  -f, --force       Force installation even if directory is not empty"
      echo "  --skip-deps       Skip dependency checking"
      echo "  -h, --help        Show this help message"
      echo
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
  echo "Creating directory: $TARGET_DIR"
  mkdir -p "$TARGET_DIR"
fi

# Check if target directory is empty (unless force install)
if [ "$FORCE_INSTALL" != "true" ] && [ "$(ls -A "$TARGET_DIR")" ]; then
  echo "Error: Directory '$TARGET_DIR' is not empty."
  echo "Use -f or --force to install anyway."
  exit 1
fi

# Move to target directory
cd "$TARGET_DIR"

# Check dependencies
if [ "$SKIP_DEPENDENCIES" != "true" ]; then
  echo "Checking dependencies..."
  
  # Check for rsync (used by this script)
  if ! command -v rsync &> /dev/null; then
    echo "Error: rsync not found. This is required for installation."
    echo "  - Homebrew: brew install rsync"
    echo "  - Apt: sudo apt-get install rsync"
    echo "  - Yum: sudo yum install rsync"
    exit 1
  fi
  
  # Check for Quarto
  if ! command -v quarto &> /dev/null; then
    echo "Warning: Quarto not found. Please install Quarto:"
    echo "  - Website: https://quarto.org/docs/get-started/"
    echo "  - Homebrew: brew install --cask quarto"
    echo "  - Conda: conda install -c conda-forge quarto"
    echo "Continuing installation, but you'll need Quarto to use the template."
  fi
  
  # Check for LaTeX/pdflatex (needed for TikZ)
  if ! command -v pdflatex &> /dev/null; then
    echo "Warning: pdflatex not found. You'll need LaTeX for TikZ diagrams."
    echo "  - Homebrew: brew install --cask mactex-no-gui"
    echo "  - Conda: conda install -c conda-forge texlive-core"
    echo "  - Apt: sudo apt-get install texlive"
    echo "  - Alternatively, install TeX Live or MiKTeX"
    echo "Continuing installation..."
  fi
  
  # Check for ImageMagick (needed for TikZ rendering)
  if ! command -v convert &> /dev/null; then
    echo "Warning: ImageMagick not found. You'll need it for TikZ diagram conversion."
    echo "  - Homebrew: brew install imagemagick"
    echo "  - Conda: conda install -c conda-forge imagemagick"
    echo "  - Apt: sudo apt-get install imagemagick"
    echo "  - Website: https://imagemagick.org/script/download.php"
    echo "Continuing installation..."
  fi
  
  # Check for npm (for Mermaid dependencies)
  if ! command -v npm &> /dev/null; then
    echo "Warning: npm not found. This is needed for Mermaid customizations."
    echo "  - Homebrew: brew install node"
    echo "  - Conda: conda install -c conda-forge nodejs"
    echo "  - Apt: sudo apt-get install nodejs npm"
    echo "  - Website: https://nodejs.org/"
    echo "Continuing installation, but Mermaid diagrams may not render correctly."
  fi
fi  # End of dependency checking

# Function to handle download errors
download_with_retry() {
  local url=$1
  local output=$2
  local max_retries=3
  local retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    if curl -sSL "$url" -o "$output"; then
      return 0
    else
      echo "Download failed. Retrying ($((retry_count + 1))/$max_retries)..."
      retry_count=$((retry_count + 1))
      sleep 2
    fi
  done
  
  echo "Failed to download $url after $max_retries attempts."
  return 1
}

# Either clone the repo or create the structure manually
if command -v git &> /dev/null; then
  echo "Git found. Cloning template repository..."
  # Create a temporary directory for cloning
  TEMP_DIR=$(mktemp -d)
  
  # Try cloning with retries
  retry_count=0
  max_retries=3
  while [ $retry_count -lt $max_retries ]; do
    if git clone "$REPO_URL" "$TEMP_DIR"; then
      break
    else
      echo "Git clone failed. Retrying ($((retry_count + 1))/$max_retries)..."
      retry_count=$((retry_count + 1))
      sleep 2
      
      if [ $retry_count -eq $max_retries ]; then
        echo "Failed to clone repository after $max_retries attempts."
        rm -rf "$TEMP_DIR"
        exit 1
      fi
    fi
  done
  
  # Move contents to target directory (excluding git files)
  echo "Setting up template files..."
  rsync -a --exclude='.git' --exclude='node_modules' "$TEMP_DIR/" ./
  
  # Clean up
  rm -rf "$TEMP_DIR"
else
  echo "Git not found. Creating directory structure manually..."
  
  # Create directory structure
  mkdir -p _customizations/{mermaid,syntax/_highlight,tikz}
  mkdir -p _extensions/{syntax-enhance,tikz-prerender}
  mkdir -p _tikz
  
  # Here you would download individual files or create them...
  echo "Manual file creation not implemented yet."
  echo "Please install git and retry, or download the template from:"
  echo "https://github.com/felixleopold/quarto-template"
  exit 1
fi

# Make shell scripts executable
chmod +x _customizations/tikz/prerender-tikz.sh
chmod +x _extensions/tikz-prerender/install.sh
chmod +x setup.sh 2>/dev/null || true

# Install Node.js dependencies for Mermaid if npm is available
if command -v npm &> /dev/null && [ -f "_customizations/mermaid/package.json" ]; then
  echo "Installing Mermaid dependencies..."
  (cd _customizations/mermaid && npm install --no-fund --no-audit --loglevel=error)
else
  echo "Skipping Mermaid dependency installation (npm not found or package.json missing)."
fi

# Run the TikZ prerender extension installer
echo "Initializing TikZ prerender extension..."
# Make sure the extension installer uses the files in their current locations
(cd _extensions/tikz-prerender && ./install.sh)

# Create starter document if example.qmd doesn't exist
if [ ! -f "example.qmd" ]; then
  echo "Creating starter document: starter.qmd"
  cat > starter.qmd << 'EOL'
---
title: "My Quarto Document with TikZ and Mermaid"
format:
  html: default
  pdf: default
tikz_prerender: true
---

## TikZ Diagram Example

```{=latex}
\begin{tikzpicture}
\draw[ultra thick, red] (-2,0) -- (2,0);
\draw[ultra thick, blue] (0,-2) -- (0,2);
\node at (0,0) [fill=yellow, circle, inner sep=10pt] {TikZ};
\end{tikzpicture}
```

## Mermaid Diagram Example

```{mermaid}
flowchart LR
  A[Start] --> B{Decision}
  B -->|Yes| C[Action 1]
  B -->|No| D[Action 2]
  C --> E[End]
  D --> E
```

## Code Example

```python
def hello_world():
    print("Hello, world!")
    return None

if __name__ == "__main__":
    hello_world()
```
EOL
fi

# Verification step
echo
echo "🔍 Verifying installation..."
verification_errors=0

# Check if key files exist
if [ ! -f "_quarto.yml" ]; then
  echo "❌ _quarto.yml is missing"
  verification_errors=$((verification_errors + 1))
fi

if [ ! -f "_customizations/tikz/prerender-tikz.sh" ]; then
  echo "❌ TikZ prerendering script is missing"
  verification_errors=$((verification_errors + 1))
fi

if [ ! -f "_customizations/mermaid/mermaid-override.html" ]; then
  echo "❌ Mermaid customizations are missing"
  verification_errors=$((verification_errors + 1))
fi

# Final status message
if [ $verification_errors -eq 0 ]; then
  echo "✅ Template installation complete and verified!"
  echo
  echo "====== NEXT STEPS ======"
  echo
  echo "1. QUARTO ENVIRONMENT SETUP:"
  echo "   • Ensure Quarto is installed: https://quarto.org/docs/get-started/"
  echo "     'brew install --cask quarto'"
  echo
  echo "   • Required dependencies:"
  echo "     - LaTeX/pdflatex (for TikZ): 'brew install --cask mactex-no-gui'"
  echo "       conda: 'conda install -c conda-forge texlive-core texlive-latex-extra'"
  echo "     - ImageMagick (for image conversion): 'brew install imagemagick'"
  echo "       conda: 'conda install -c conda-forge imagemagick'"
  echo "     - Node.js/npm (for Mermaid): 'brew install node'"
  echo "       conda: 'conda install -c conda-forge nodejs'"
  echo
  echo "   • For best results, use a dedicated conda environment:"
  echo
  echo "     # Create a conda environment for Quarto projects"
  echo "     'conda create -n quarto python=3.10 jupyter matplotlib pandas numpy scipy'"
  echo "     'conda activate quarto'"
  echo "     'conda install -c conda-forge texlive-core imagemagick nodejs jupyter-book r-base'"
  echo
  echo "2. RENDERING YOUR DOCUMENT:"
  echo "   • Activate your environment first: 'conda activate quarto'"
  echo "   • Then render: 'quarto render example.qmd'"
  echo "   • For preview server: 'quarto preview example.qmd'"
  echo
  echo "3. AVAILABLE FEATURES:"
  echo "   • TikZ diagrams: Write LaTeX TikZ in {=latex} code blocks"
  echo "   • Python code: Write Python code in {python} code blocks"
  echo "   • Mermaid diagrams: Write in {mermaid} code blocks"
  echo "   • Jupyter: Run Python code directly in the document"
  echo
  echo "For more details and examples, see the example.qmd file and README.md"
else
  echo "⚠️ Template installation completed with $verification_errors verification issues."
  echo "Please check the output above for details."
fi 