# TikZ Prerendering Extension for Quarto

This extension automatically prerenders TikZ diagrams into PNG images for HTML output, providing a seamless experience with minimal configuration.

## Features

- Automatic prerendering of TikZ diagrams when `tikz_prerender: true` is set in the document frontmatter
- Works with both inline document rendering and project rendering
- Generates deterministic IDs for TikZ diagrams based on content, allowing for caching
- Full transparency support for diagrams
- Fallback to direct rendering if the prerender script fails
- Debug mode with saved LaTeX files for troubleshooting

## Installation

1. Copy the `tikz-prerender` directory to your Quarto project's `_extensions` directory
2. Run the installation script:
   ```bash
   ./_extensions/tikz-prerender/install.sh
   ```
3. Make sure the `prerender-tikz.sh` script is in your project root directory and executable:
   ```bash
   chmod +x prerender-tikz.sh
   ```

## Usage

1. Add `tikz_prerender: true` to your document's YAML frontmatter:
   ```yaml
   ---
   title: "My Document with TikZ Diagrams"
   format:
     html: default
     pdf: default
   tikz_prerender: true
   ---
   ```

2. Write TikZ diagrams in LaTeX blocks using the `{=latex}` format:
   ````markdown
   ```{=latex}
   \begin{tikzpicture}
   \draw[ultra thick, red] (-2,0) -- (2,0);
   \draw[ultra thick, blue] (0,-2) -- (0,2);
   \node at (0,0) [fill=yellow, circle, inner sep=10pt] {TikZ};
   \end{tikzpicture}
   ```
   ````

3. When rendering to HTML, the diagrams will be automatically prerendered to PNG images.

## Configuration

The prerender script supports several environment variables for customization:

- `OUTPUT_DIR`: Directory to store rendered images (default: `_tikz`)
- `DENSITY`: Image resolution in DPI (default: 300)
- `QUALITY`: Image quality (default: 100)
- `BORDER`: Border around TikZ diagrams (default: 5pt)
- `TIKZ_LIBRARIES`: Comma-separated list of TikZ libraries to load

You can also run the prerender script manually:

```bash
./prerender-tikz.sh [--force] [file.qmd]
```

## Requirements

- LaTeX with TikZ packages installed
- ImageMagick for converting PDF to PNG
- Bash shell

## Troubleshooting

If diagrams fail to render:

1. Check the console for error messages
2. Look in the `_tikz_debug` directory for the LaTeX source files
3. Try compiling them manually with pdflatex
4. Make sure your TikZ syntax is correct

## License

MIT License 