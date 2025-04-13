# Quarto TikZ and Mermaid Template

A ready-to-use Quarto template with beautiful Gruvbox-themed TikZ diagrams, Mermaid charts, and enhanced syntax highlighting.

## Features

- **Automatic TikZ Prerendering**: TikZ diagrams are converted to PNG images for HTML output while keeping vector format for PDF
- **Mermaid Diagrams**: Custom Gruvbox theme for consistent styling of Mermaid diagrams
- **Enhanced Syntax Highlighting**: 
  - Gruvbox-themed syntax highlighting for code
  - Rainbow parentheses/brackets for better readability
  - Special styling for Python error types and constants
- **Consistent styling**: Same visual appearance across HTML and PDF outputs

## Quick Start

One-line installation:

```bash
curl -sSL https://raw.githubusercontent.com/felixleopold/quarto-template/main/setup.sh | bash
```

Or specify a directory:

```bash
curl -sSL https://raw.githubusercontent.com/felixleopold/quarto-template/main/setup.sh | bash -s -- -d my-project
```

## Installation Options

### Option 1: Quick Install Script (Recommended)

```bash
# Install in current directory
curl -sSL https://raw.githubusercontent.com/felixleopold/quarto-template/main/setup.sh | bash

# Or install in a specific directory
curl -sSL https://raw.githubusercontent.com/felixleopold/quarto-template/main/setup.sh | bash -s -- -d my-project

# Force installation in a non-empty directory
curl -sSL https://raw.githubusercontent.com/felixleopold/quarto-template/main/setup.sh | bash -s -- -f
```

### Option 2: Clone the Repository

```bash
git clone https://github.com/felixleopold/quarto-template.git my-project
cd my-project
chmod +x _extensions/tikz-prerender/install.sh
./_extensions/tikz-prerender/install.sh
```

### Option 3: Download ZIP

1. Download the [latest release](https://github.com/felixleopold/quarto-template/releases/latest)
2. Extract to your project directory
3. Make scripts executable:
   ```bash
   chmod +x _customizations/tikz/prerender-tikz.sh
   chmod +x _extensions/tikz-prerender/install.sh
   ```
4. Run the extension installer:
   ```bash
   ./_extensions/tikz-prerender/install.sh
   ```

## Requirements

- **Quarto**: For document rendering
  - [Official website](https://quarto.org/docs/get-started/)
  - Homebrew: `brew install --cask quarto`
  - Conda: `conda install -c conda-forge quarto`

- **LaTeX**: For TikZ diagrams
  - Homebrew: `brew install --cask mactex`
  - Conda: `conda install -c conda-forge texlive-core`
  - Apt: `sudo apt-get install texlive`
  - Or install [TeX Live](https://www.tug.org/texlive/) / [MiKTeX](https://miktex.org/)

- **ImageMagick**: For converting PDF diagrams to PNG
  - Homebrew: `brew install imagemagick`
  - Conda: `conda install -c conda-forge imagemagick`
  - Apt: `sudo apt-get install imagemagick`
  - [Official website](https://imagemagick.org/script/download.php)

- **Node.js/npm**: For Mermaid customizations
  - Homebrew: `brew install node`
  - Conda: `conda install -c conda-forge nodejs`
  - Apt: `sudo apt-get install nodejs npm`
  - [Official website](https://nodejs.org/)

## Usage

1. Add `tikz_prerender: true` to your document's YAML frontmatter
2. Create TikZ diagrams using `{=latex}` code blocks
3. Create Mermaid diagrams using `{mermaid}` code blocks
4. Render with `quarto render`

### TikZ Example

````markdown
```{=latex}
\begin{tikzpicture}
\draw[ultra thick, red] (-2,0) -- (2,0);
\draw[ultra thick, blue] (0,-2) -- (0,2);
\node at (0,0) [fill=yellow, circle, inner sep=10pt] {TikZ};
\end{tikzpicture}
```
````

### Mermaid Example

````markdown
```{mermaid}
flowchart LR
  A[Start] --> B{Decision}
  B -->|Yes| C[Action 1]
  B -->|No| D[Action 2]
  C --> E[End]
  D --> E
```
````

## Directory Structure

```
.
├── _customizations/                 # All custom enhancements
│   ├── mermaid/                     # Mermaid styling
│   ├── syntax/                      # Syntax highlighting 
│   └── tikz/                        # TikZ rendering support
├── _extensions/                     # Quarto extensions
│   ├── syntax-enhance/              # Syntax enhancement extension
│   └── tikz-prerender/              # TikZ prerendering extension
├── _tikz/                           # Rendered TikZ images
├── example.qmd                      # Example document
└── _quarto.yml                      # Quarto configuration
```

## Customization

- **Theme Colors**: Edit the Gruvbox theme colors in `_quarto.yml` and `_customizations/mermaid/mermaid-override.html`
- **TikZ Libraries**: Add additional libraries in `_customizations/tikz/prerender-tikz.sh`
- **Syntax Highlighting**: Modify `_customizations/syntax/syntax-enhance.js` for code styling

## License

MIT 
