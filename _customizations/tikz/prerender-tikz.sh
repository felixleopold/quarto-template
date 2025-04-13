#!/bin/bash

# Script to prerender TikZ diagrams for HTML output in Quarto
# Creates PNG images from TikZ code in {=latex} blocks

set -e  # Exit on error

# Configuration (can be overridden with environment variables)
OUTPUT_DIR="${OUTPUT_DIR:-_tikz}"
DENSITY="${DENSITY:-300}"
QUALITY="${QUALITY:-100}"
BORDER="${BORDER:-5pt}"
TIKZ_LIBRARIES="${TIKZ_LIBRARIES:-arrows,shapes,positioning,calc,fit,backgrounds,decorations.pathreplacing,calligraphy}"
FORCE_REBUILD="${FORCE_REBUILD:-false}"
SINGLE_FILE=""

# Help message
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 [options] [file.qmd]"
  echo 
  echo "Options:"
  echo "  -f, --force     Force rebuild all TikZ diagrams"
  echo "  -h, --help      Show this help message"
  echo
  echo "Arguments:"
  echo "  [file.qmd]      Process only this specific file"
  echo
  echo "Environment variables:"
  echo "  OUTPUT_DIR      Directory to store rendered images (default: _tikz)"
  echo "  DENSITY         Image resolution in DPI (default: 300)"
  echo "  QUALITY         Image quality (default: 100)"
  echo "  BORDER          Border around TikZ diagrams (default: 5pt)"
  echo "  TIKZ_LIBRARIES  Comma-separated list of TikZ libraries to load"
  echo
  exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      FORCE_REBUILD=true
      shift
      ;;
    *.qmd|*.md)
      SINGLE_FILE="$1"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check for required commands
for cmd in pdflatex convert sed grep; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: Required command '$cmd' not found"
    case $cmd in
      pdflatex)
        echo "Please install TeX Live or similar LaTeX distribution"
        ;;
      convert)
        echo "Please install ImageMagick"
        ;;
      *)
        echo "Please install required dependencies"
        ;;
    esac
    exit 1
  fi
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR"

# Also create debug directory
DEBUG_DIR="_tikz_debug"
mkdir -p "$DEBUG_DIR"

# Count for statistics
total_blocks=0
rendered_blocks=0
skipped_blocks=0
failed_blocks=0

# Generate ID using simple hash algorithm that matches the Lua filter
# Must produce the same IDs as the Lua filter
generate_tikz_id() {
  local content="$1"
  local hash=0
  
  # For each character in the content
  for (( i=0; i<${#content}; i++ )); do
    # Get the ASCII value of the character
    char_code=$(printf "%d" "'${content:$i:1}")
    # Apply the same hash algorithm as in the Lua filter
    hash=$(( (hash * 31 + char_code) % 0xFFFFFFFF ))
  done
  
  # Format hash as 8-char hexadecimal string, same as in Lua filter
  printf "tikz-%08x" $hash | cut -c 1-13
}

# Process a single TikZ block from LaTeX content
process_tikz_block() {
  local tikz_content="$1"
  local source_file="$2"
  
  # Clean up the content (remove leading/trailing whitespace)
  tikz_content=$(echo "$tikz_content" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  
  if [[ -n "$tikz_content" ]]; then
    ((total_blocks++))
    
    # Generate a deterministic ID that matches Lua filter's method
    local tikz_id=$(generate_tikz_id "$tikz_content")
    local output_path="$OUTPUT_DIR/${tikz_id}.png"
    
    # Check if we need to regenerate the image
    if [[ "$FORCE_REBUILD" == "true" || ! -f "$output_path" ]]; then
      echo "  Creating image for TikZ diagram: $tikz_id (from $source_file)"
      
      # Create a temporary LaTeX file
      temp_dir=$(mktemp -d)
      temp_file="$temp_dir/tikz_temp.tex"
      
      # Create a standalone LaTeX document with the TikZ code
      cat > "$temp_file" << EOF
\\documentclass[border=$BORDER]{standalone}
\\usepackage{tikz}
\\usepackage{xcolor}
\\usepackage{pgfplots}
\\pgfplotsset{compat=newest}
\\usetikzlibrary{$TIKZ_LIBRARIES}
\\begin{document}
\\begin{tikzpicture}
$tikz_content
\\end{tikzpicture}
\\end{document}
EOF
      
      # Also save to debug directory for reference
      cp "$temp_file" "$DEBUG_DIR/${tikz_id}.tex"
      
      # Compile the LaTeX to PDF
      (cd "$temp_dir" && pdflatex -interaction=nonstopmode tikz_temp.tex > /dev/null 2>&1)
      
      # Convert PDF to PNG with transparent background
      if [[ -f "$temp_dir/tikz_temp.pdf" ]]; then
        convert -density "$DENSITY" -background transparent "$temp_dir/tikz_temp.pdf" -quality "$QUALITY" "$output_path"
        echo "  Created $output_path"
        ((rendered_blocks++))
      else
        echo "  Error: Failed to compile TikZ to PDF for $tikz_id"
        echo "  Check your TikZ syntax in $source_file"
        # Save the problematic code for debugging
        error_file="$OUTPUT_DIR/${tikz_id}_error.tex"
        cp "$temp_file" "$error_file"
        echo "  LaTeX source saved to $error_file for debugging"
        ((failed_blocks++))
      fi
      
      # Clean up
      rm -rf "$temp_dir"
    else
      echo "  Skipping existing image: $tikz_id"
      ((skipped_blocks++))
    fi
  fi
}

# Process Markdown and Quarto files
echo "Scanning for TikZ diagrams in *.md and *.qmd files..."

# Function to process a single file
process_file() {
  local file="$1"
  echo "Processing $file"
  
  # Extract all LaTeX blocks containing TikZ diagrams
  # First, extract all raw LaTeX blocks between ```{=latex} and ```
  latex_blocks=$(awk '/^```{=latex}/,/^```/ { print }' "$file" | sed '/^```/d; /^```{=latex}/d')
  
  # Then extract TikZ content from each block
  while read -r line; do
    if [[ "$line" == *"\\begin{tikzpicture}"* ]]; then
      # Start of TikZ environment
      in_tikz=true
      tikz_content=""
      continue
    fi
    
    if [[ "$in_tikz" == true && "$line" == *"\\end{tikzpicture}"* ]]; then
      # End of TikZ environment, process it
      process_tikz_block "$tikz_content" "$file"
      in_tikz=false
    fi
    
    if [[ "$in_tikz" == true ]]; then
      # Accumulate TikZ content
      tikz_content+="$line"$'\n'
    fi
  done <<< "$latex_blocks"
}

# Decide whether to process a single file or all files
if [[ -n "$SINGLE_FILE" ]]; then
  if [[ -f "$SINGLE_FILE" ]]; then
    process_file "$SINGLE_FILE"
  else
    echo "Error: File $SINGLE_FILE not found"
    exit 1
  fi
else
  # Process all Markdown and Quarto files
  for file in $(find . -name "*.md" -o -name "*.qmd" | grep -v "/_"); do
    process_file "$file"
  done
fi

# Always process any debug files in _tikz_debug
if [[ -d "$DEBUG_DIR" ]]; then
  for debug_file in "$DEBUG_DIR"/*.tex; do
    if [[ -f "$debug_file" ]]; then
      # Extract basename without extension
      base_name=$(basename "$debug_file" .tex)
      output_path="$OUTPUT_DIR/${base_name}.png"
      
      if [[ "$FORCE_REBUILD" == "true" || ! -f "$output_path" ]]; then
        echo "  Rendering TikZ diagram from debug file: $debug_file"
        
        # Compile the LaTeX to PDF
        temp_dir=$(mktemp -d)
        cp "$debug_file" "$temp_dir/tikz_temp.tex"
        (cd "$temp_dir" && pdflatex -interaction=nonstopmode tikz_temp.tex > /dev/null 2>&1)
        
        # Convert PDF to PNG with transparent background
        if [[ -f "$temp_dir/tikz_temp.pdf" ]]; then
          convert -density "$DENSITY" -background transparent "$temp_dir/tikz_temp.pdf" -quality "$QUALITY" "$output_path"
          echo "  Created $output_path"
          ((rendered_blocks++))
        else
          echo "  Error: Failed to compile TikZ from debug file: $debug_file"
          ((failed_blocks++))
        fi
        
        # Clean up
        rm -rf "$temp_dir"
      fi
    fi
  done
fi

# Print statistics
echo 
echo "TikZ diagrams prerendering complete!"
echo "---------------------------------------"
echo "Total diagrams found:  $total_blocks"
echo "New diagrams rendered: $rendered_blocks"
echo "Existing diagrams:     $skipped_blocks"
echo "Failed to render:      $failed_blocks"
echo "---------------------------------------"
echo "Generated images are in the $OUTPUT_DIR directory"

# Exit with error if any diagrams failed
if [[ $failed_blocks -gt 0 ]]; then
  echo "Warning: Some diagrams failed to render. Check error messages above."
  exit 1
fi 