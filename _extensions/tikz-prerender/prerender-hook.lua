-- Quarto pre-render hook for TikZ prerendering
-- This hook will check for tikz_prerender: true in the frontmatter
-- and run the prerender-tikz.sh script if enabled

-- Run a command and return its output
local function run_command(cmd)
  local handle = io.popen(cmd .. " 2>&1", "r")
  local output = handle:read("*all")
  local success = handle:close()
  return success, output
end

-- Process TikZ code directly from Lua
local function process_tikz_directly(tikz_content, tikz_id)
  -- Create output directories if they don't exist
  os.execute("mkdir -p _tikz _tikz_debug")
  
  -- Generate a LaTeX file for this TikZ diagram
  local temp_file = "_tikz_debug/" .. tikz_id .. ".tex"
  local f = io.open(temp_file, "w")
  if not f then
    io.stderr:write("Error: Could not create temporary LaTeX file\n")
    return false
  end
  
  f:write("\\documentclass[border=5pt]{standalone}\n")
  f:write("\\usepackage{tikz}\n")
  f:write("\\usepackage{xcolor}\n")
  f:write("\\usepackage{pgfplots}\n")
  f:write("\\pgfplotsset{compat=newest}\n")
  f:write("\\usetikzlibrary{arrows,shapes,positioning,calc,fit,backgrounds,decorations.pathreplacing,calligraphy}\n")
  f:write("\\begin{document}\n")
  f:write("\\begin{tikzpicture}\n")
  f:write(tikz_content)
  f:write("\n\\end{tikzpicture}\n")
  f:write("\\end{document}\n")
  f:close()
  
  -- Compile the LaTeX file to PDF
  local success, output = run_command("cd _tikz_debug && pdflatex -interaction=nonstopmode " .. tikz_id .. ".tex")
  if not success then
    io.stderr:write("Error compiling LaTeX: " .. output .. "\n")
    return false
  end
  
  -- Convert the PDF to PNG
  local output_file = "_tikz/" .. tikz_id .. ".png"
  success, output = run_command("convert -density 300 -background transparent _tikz_debug/" .. tikz_id .. ".pdf -quality 100 " .. output_file)
  if not success then
    io.stderr:write("Error converting PDF to PNG: " .. output .. "\n")
    return false
  end
  
  return true
end

-- Generate TikZ ID from content
local function generate_tikz_id(content)
  -- Simple implementation of a string hash similar to MD5 first 8 chars
  local hash = 0
  for i = 1, #content do
    hash = (hash * 31 + content:byte(i)) % 0xFFFFFFFF
  end
  return "tikz-" .. string.format("%08x", hash):sub(1, 8)
end

-- Main prerender function
function FormatOptions(meta)
  -- Get the tikz_prerender option from frontmatter, default to false
  local tikz_prerender = meta.tikz_prerender
  
  -- Convert YAML boolean to Lua boolean
  if type(tikz_prerender) == "boolean" and tikz_prerender or
     tikz_prerender == "true" or tikz_prerender == true then
    
    io.stderr:write("\nTikZ prerendering is enabled. Checking environment...\n")
    
    -- First try running the shell script
    local success, output = run_command("bash -c './_customizations/tikz/prerender-tikz.sh --help'")
    if success then
      io.stderr:write("Found prerender-tikz.sh script. Running...\n")
      
      -- Get input file if possible
      local input_file = nil
      if quarto and quarto.doc and quarto.doc.input_file then
        input_file = quarto.doc.input_file
      elseif meta.filename then
        input_file = meta.filename
      end
      
      local cmd
      if input_file then
        cmd = "./_customizations/tikz/prerender-tikz.sh \"" .. input_file .. "\""
      else
        cmd = "./_customizations/tikz/prerender-tikz.sh"
      end
      
      success, output = run_command(cmd)
      if success then
        io.stderr:write("TikZ prerendering completed successfully!\n")
      else
        io.stderr:write("Warning: TikZ prerendering script failed. Will try to process inline.\n")
        io.stderr:write("Error: " .. output .. "\n")
      end
    else
      io.stderr:write("Could not run prerender-tikz.sh. Will try to process TikZ diagrams directly.\n")
    end
  end
end

-- Register the format options callback
return {
  {
    Meta = function(meta)
      FormatOptions(meta)
      return meta
    end
  }
} 