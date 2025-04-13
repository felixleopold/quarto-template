-- Enhanced syntax highlighting for Quarto
-- This filter applies additional syntax highlighting to code blocks
-- after Pandoc has already processed them with its highlighter

-- Python error types
local python_error_types = {
  "Exception", "Error", "ValueError", "TypeError", "KeyError", "IndexError",
  "RuntimeError", "FileNotFoundError", "ImportError", "AttributeError"
}

-- Safe pattern replacement function that avoids replacing inside HTML tags
local function safe_pattern_replace(html, pattern, replacement)
  local result = ""
  local pos = 1
  local in_tag = false
  
  while pos <= #html do
    if html:sub(pos, pos) == "<" then
      in_tag = true
    elseif html:sub(pos, pos) == ">" then
      in_tag = false
    end
    
    if not in_tag then
      local start, finish, capture = html:find(pattern, pos)
      if start then
        -- Add content before the match
        result = result .. html:sub(pos, start - 1)
        -- Add the replacement with the capture group
        result = result .. string.format(replacement, capture)
        pos = finish + 1
      else
        -- No more matches, add the rest of the content
        result = result .. html:sub(pos)
        break
      end
    else
      -- Inside a tag, just add the character
      result = result .. html:sub(pos, pos)
      pos = pos + 1
    end
  end
  
  return result
end

-- A simpler approach: just apply a few targeted enhancements
local function enhance_python_code(html)
  -- For Authentication class specifically (safely)
  html = safe_pattern_replace(
    html,
    '([^<])(Authentication)([^>])', 
    '%1<span class="cl" style="color: #fabd2f; font-weight: bold;">%2</span>%3'
  )
  
  -- For error types (making them yellow, but safely)
  for _, error_type in ipairs(python_error_types) do
    html = safe_pattern_replace(
      html,
      '([^>a-zA-Z0-9_])(' .. error_type .. ')([^a-zA-Z0-9_<])', 
      '%1<span class="er" style="color: #fabd2f;">%2</span>%3'
    )
  end
  
  return html
end

function RawBlock(el)
  -- Only process HTML blocks
  if el.format ~= "html" then
    return el
  end
  
  -- Check if this is a code block with Python
  if el.text:find('<div class="sourceCode" id=".*"><pre class="sourceCode python">') then
    -- Apply our Python enhancements
    el.text = enhance_python_code(el.text)
  end
  
  return el
end

return {
  {
    RawBlock = RawBlock
  }
} 