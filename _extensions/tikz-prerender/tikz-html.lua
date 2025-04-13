-- TikZ HTML Filter for Quarto
-- This filter processes TikZ diagrams in {=latex} blocks for HTML output
-- For PDF output, the {=latex} blocks remain untouched

local function extract_tikz_content(latex_code)
  -- Extract content between \begin{tikzpicture} and \end{tikzpicture}
  local tikz_content = latex_code:match("\\begin{tikzpicture}(.-)\\end{tikzpicture}")
  if not tikz_content then return nil end
  return tikz_content
end

local function extract_caption(latex_code)
  -- Extract caption from a figure environment
  return latex_code:match("\\caption{(.-)}")
end

local function get_tikz_id(content)
  -- Generate a deterministic ID based on MD5-like hash to match prerender-tikz.sh
  -- Simple implementation of a string hash similar to MD5 first 8 chars
  local hash = 0
  for i = 1, #content do
    hash = (hash * 31 + content:byte(i)) % 0xFFFFFFFF
  end
  return "tikz-" .. string.format("%08x", hash):sub(1, 8)
end

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
  
  -- Try compiling directly
  io.stderr:write("Attempting to render TikZ diagram " .. tikz_id .. " directly...\n")
  local output_file = "_tikz/" .. tikz_id .. ".png"
  
  -- Run command to compile with pdflatex and convert to PNG
  local cmd = "cd _tikz_debug && pdflatex -interaction=nonstopmode " .. tikz_id .. ".tex && "
  cmd = cmd .. "convert -density 300 -background none " .. tikz_id .. ".pdf -quality 100 ../" .. output_file
  
  local success, output = run_command(cmd)
  
  if success then
    io.stderr:write("Successfully rendered " .. output_file .. "\n")
    return true
  else
    io.stderr:write("Failed to render TikZ diagram directly: " .. output .. "\n")
    return false
  end
end

-- Function to check if file exists
local function file_exists(path)
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end

return {
  {
    RawBlock = function(el)
      -- Only process LaTeX blocks in HTML output
      if el.format ~= "latex" or FORMAT ~= "html" then
        return el
      end
      
      -- Check if this is a TikZ diagram by looking for tikzpicture environment
      if not el.text:match("\\begin{tikzpicture}") then
        return el
      end
      
      -- Extract the TikZ content
      local tikz_content = extract_tikz_content(el.text)
      if not tikz_content then
        return el
      end
      
      -- Get caption if available
      local caption = extract_caption(el.text)
      
      -- Generate a unique ID for this TikZ diagram (matching prerender-tikz.sh behavior)
      local tikz_id = get_tikz_id(tikz_content)
      local image_path = "_tikz/" .. tikz_id .. ".png"
      
      -- Check if image exists
      if not file_exists(image_path) then
        -- Try to render the image directly if it doesn't exist
        local render_success = process_tikz_directly(tikz_content, tikz_id)
        
        -- If direct rendering also failed, create a placeholder
        if not render_success then
          io.stderr:write("WARNING: TikZ image not found or failed to render: " .. image_path .. 
                          "\nRun the prerender-tikz.sh script first to generate TikZ images.\n")
          
          -- Create a debug file with the TikZ content for easy rendering
          local debug_dir = "_tikz_debug"
          os.execute("mkdir -p " .. debug_dir)
          local debug_file = debug_dir .. "/" .. tikz_id .. ".tex"
          local f = io.open(debug_file, "w")
          if f then
            f:write("\\documentclass[border=5pt]{standalone}\n")
            f:write("\\usepackage{tikz}\n")
            f:write("\\usepackage{xcolor}\n")
            f:write("\\usepackage{pgfplots}\n")
            f:write("\\pgfplotsset{compat=newest}\n")
            
            -- Match libraries with the shell script
            f:write("\\usetikzlibrary{arrows,shapes,positioning,calc,fit,backgrounds,decorations.pathreplacing,calligraphy}\n")
            f:write("\\begin{document}\n")
            f:write("\\begin{tikzpicture}\n")
            f:write(tikz_content)
            f:write("\n\\end{tikzpicture}\n")
            f:write("\\end{document}\n")
            f:close()
            io.stderr:write("TikZ code saved to " .. debug_file .. " for manual rendering.\n")
            io.stderr:write("Run './prerender-tikz.sh' to render this diagram.\n")
          end
          
          local error_div = pandoc.Div(
            {pandoc.Para(
              {pandoc.Strong("TikZ diagram not pre-rendered:"), 
               pandoc.Space(),
               pandoc.Str("Run prerender-tikz.sh script to generate " .. tikz_id .. ".png")}
            )},
            {class = "tikz-error"}
          )
          return error_div
        end
      end
      
      -- Create an image element with the pre-rendered TikZ diagram
      local image = pandoc.Image("", image_path)
      
      -- Add alt text for accessibility
      image.attributes.alt = caption or "TikZ diagram"
      
      -- Prepare figure content
      local figure_content = {image}
      
      -- Add caption if specified
      if caption then
        table.insert(figure_content, pandoc.Para({pandoc.Emph(caption)}))
      end
      
      -- Create figure object with proper attributes
      local figure_attrs = {
        class = "tikz-figure", 
        id = tikz_id
      }
      
      -- Return the image wrapped in a styled div
      -- First create the figure with image and caption
      local figure = pandoc.Div(figure_content, figure_attrs)
      
      -- Then wrap the figure in a container div for styling
      local container_attrs = {
        class = "tikz-container"
      }
      
      return pandoc.Div({figure}, container_attrs)
    end
  }
} 