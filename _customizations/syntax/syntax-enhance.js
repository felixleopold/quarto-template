// Script to enhance syntax highlighting
document.addEventListener('DOMContentLoaded', function() {
  // Function to enhance syntax highlighting - we'll call this after a delay to ensure Quarto has finished
  function enhanceSyntaxHighlighting() {
    console.log("Applying syntax enhancement...");
    // Function to get all Python code blocks
    const codeBlocks = document.querySelectorAll('code.sourceCode.python');
    console.log("Found", codeBlocks.length, "Python code blocks");
    
    // Gruvbox theme colors - exact colors from VSCode theme
    const colors = {
      bg: "#282828",
      fg: "#ebdbb2",
      red: "#fb4934",         // Bright red for keywords
      green: "#b8bb26",       // Bright green for strings
      yellow: "#fabd2f",      // Bright yellow for classes/types
      blue: "#83a598",        // Bright blue for variables/parameters
      purple: "#d3869b",      // For special values like None
      darkPurple: "#b16286",  // For brackets
      aqua: "#8ec07c",        // For function calls
      orange: "#fe8019",      // For built-in functions
      gray: "#928374"         // For comments
    };
    
    // Rainbow colors for nested brackets/parentheses
    const bracketColors = [
      colors.purple,      // Level 0 - Purple
      colors.blue,        // Level 1 - Blue
      colors.aqua,        // Level 2 - Aqua/Turquoise
      colors.green,       // Level 3 - Green
      colors.yellow,      // Level 4 - Yellow
      colors.orange,      // Level 5 - Orange
      colors.red          // Level 6 - Red
    ];
    
    // Error types to highlight in yellow
    const errorTypes = [
      "Exception", "Error", "ValueError", "TypeError", "KeyError", "IndexError",
      "RuntimeError", "FileNotFoundError", "ImportError", "AttributeError"
    ];
    
    // Style the line numbers to match comments
    const lineNumbers = document.querySelectorAll('.sourceCode a');
    lineNumbers.forEach(num => {
      num.style.color = colors.gray;
    });
    
    // Process each code block with basic styling
    codeBlocks.forEach(codeBlock => {
      console.log("Processing code block:", codeBlock.textContent.slice(0, 20) + "...");
      // Apply basic styles to common elements
      styleKeywords(codeBlock);
      styleStrings(codeBlock);
      styleComments(codeBlock);
      styleBuiltIns(codeBlock);
      styleFunctions(codeBlock);
      styleConstants(codeBlock);
      styleErrorTypes(codeBlock);
      // Apply rainbow parentheses last so it doesn't interfere with other styling
      styleRainbowParentheses(codeBlock);
    });
    
    // Helper function to style keywords
    function styleKeywords(codeBlock) {
      // Class, def, import, etc.
      const keywordSpans = codeBlock.querySelectorAll('span.kw, span.cf, span.im');
      keywordSpans.forEach(span => {
        span.style.color = colors.red;
        span.style.fontWeight = 'bold';
      });
    }
    
    // Helper function to style strings
    function styleStrings(codeBlock) {
      const stringSpans = codeBlock.querySelectorAll('span.st');
      stringSpans.forEach(span => {
        span.style.color = colors.green;
      });
    }
    
    // Helper function to style comments
    function styleComments(codeBlock) {
      const commentSpans = codeBlock.querySelectorAll('span.co');
      commentSpans.forEach(span => {
        span.style.color = colors.gray;
        span.style.fontStyle = 'italic';
      });
    }
    
    // Helper function to style built-ins
    function styleBuiltIns(codeBlock) {
      const builtinSpans = codeBlock.querySelectorAll('span.bu');
      builtinSpans.forEach(span => {
        span.style.color = colors.yellow; // Type hints are yellow
      });
    }
    
    // Helper function to style functions
    function styleFunctions(codeBlock) {
      const functionSpans = codeBlock.querySelectorAll('span.fu');
      functionSpans.forEach(span => {
        span.style.color = colors.aqua;
      });
    }
    
    // Helper function to style constants and variables
    function styleConstants(codeBlock) {
      // Style variables - default is blue
      const varSpans = codeBlock.querySelectorAll('span.va');
      varSpans.forEach(span => {
        span.style.color = colors.blue; // Default variable color
        
        // Special handling for booleans and None
        if (span.textContent === 'None' || 
            span.textContent === 'True' || 
            span.textContent === 'False') {
          span.style.color = colors.purple;
          span.classList.add('bool-value');
        } 
        // Special handling for self and cls
        else if (span.textContent === 'self' || 
                 span.textContent === 'cls') {
          span.style.color = colors.blue;
          span.classList.add('self-ref');
        }
      });
      
      // Style numbers (decimal and float)
      const numberSpans = codeBlock.querySelectorAll('span.dv, span.fl');
      numberSpans.forEach(span => {
        span.style.color = colors.purple;
      });
    }
    
    // Helper function to style rainbow parentheses
    function styleRainbowParentheses(codeBlock) {
      console.log("Applying rainbow parentheses to:", codeBlock.textContent.slice(0, 20) + "...");
      // Find all operator spans that contain brackets and parentheses
      const opSpans = Array.from(codeBlock.querySelectorAll('span.op'));
      
      if (opSpans.length === 0) {
        console.log("No operator spans found");
        return;
      }
      
      // Map each bracket/parenthesis character to its position and span
      const bracketChars = [];
      
      // Map all bracket characters to their spans and positions
      opSpans.forEach(span => {
        const text = span.textContent;
        // If span contains multiple characters (possible with some tokenizations)
        for (let i = 0; i < text.length; i++) {
          const char = text[i];
          if ('()[]{}'.includes(char)) {
            bracketChars.push({
              char: char,
              span: span,
              multiChar: text.length > 1,
              position: i
            });
          }
        }
      });
      
      if (bracketChars.length === 0) {
        console.log("No bracket characters found");
        return;
      }
      
      console.log("Found", bracketChars.length, "bracket characters");
      
      // Process brackets to determine nesting levels
      const bracketStack = [];
      const bracketPairs = {};
      
      for (let i = 0; i < bracketChars.length; i++) {
        const bracket = bracketChars[i];
        const char = bracket.char;
        
        // Opening brackets - push to stack
        if ('([{'.includes(char)) {
          bracketStack.push({
            index: i,
            char: char,
            level: bracketStack.length % bracketColors.length
          });
        } 
        // Closing brackets - pop from stack and record the pair
        else if (')]}'.includes(char)) {
          if (bracketStack.length > 0) {
            const opening = bracketStack.pop();
            // Record the level for this pair
            bracketPairs[i] = opening.level;
            bracketPairs[opening.index] = opening.level;
          }
        }
      }
      
      // Second pass - apply colors based on nesting levels
      for (let i = 0; i < bracketChars.length; i++) {
        const bracket = bracketChars[i];
        const level = bracketPairs[i] !== undefined ? bracketPairs[i] : 0;
        const color = bracketColors[level];
        
        if (bracket.multiChar) {
          // If the span contains multiple characters, wrap just this bracket with its color
          const span = bracket.span;
          const originalText = span.textContent;
          
          // Only create a new span if we haven't processed this multi-character span yet
          if (!span.dataset.processed) {
            // Create a new span for each character
            let newHtml = '';
            for (let j = 0; j < originalText.length; j++) {
              const ch = originalText[j];
              if ('()[]{}'.includes(ch)) {
                // Find this char's level
                const charIndex = bracketChars.findIndex(b => 
                  b.span === span && b.position === j
                );
                const charLevel = charIndex !== -1 && bracketPairs[charIndex] !== undefined 
                  ? bracketPairs[charIndex] : 0;
                const charColor = bracketColors[charLevel];
                newHtml += `<span style="color: ${charColor};">${ch}</span>`;
              } else {
                newHtml += ch; // Keep non-bracket chars as is
              }
            }
            span.innerHTML = newHtml;
            span.dataset.processed = "true";
          }
        } else {
          // If the span is just the bracket, simply color the whole span
          bracket.span.style.color = color;
        }
      }
      
      console.log("Rainbow parentheses applied successfully");
    }
    
    // Helper function to style error types
    function styleErrorTypes(codeBlock) {
      // Get all class names and check if they're error types
      const classNameSpans = codeBlock.querySelectorAll('span.bu, span.va');
      
      // First, highlight full error class names
      classNameSpans.forEach(span => {
        if (span.textContent.endsWith('Error') || 
            span.textContent.endsWith('Exception') ||
            errorTypes.some(errType => span.textContent === errType)) {
          span.style.color = colors.yellow;
          span.classList.add('er');
        }
      });
      
      // Handle any other spans that might contain error class names
      const allSpans = codeBlock.querySelectorAll('span');
      allSpans.forEach(span => {
        // Don't process spans we've already styled or that contain other styled spans
        if (span.classList.contains('er') || span.querySelector('span')) {
          return;
        }
        
        // Check for word boundaries to avoid partial word matches
        const words = span.textContent.split(/\b/);
        words.forEach(word => {
          if (word.endsWith('Error') || 
              word.endsWith('Exception') ||
              errorTypes.includes(word)) {
            // If the span only contains the error name, style the entire span
            if (span.textContent === word) {
              span.style.color = colors.yellow;
              span.classList.add('er');
            }
            // Otherwise, we need to wrap just the error name
            else if (!span.innerHTML.includes('<span')) {
              // Use a temporary element to safely do string replacements in HTML
              const temp = document.createElement('div');
              temp.innerHTML = span.innerHTML;
              const regex = new RegExp(`\\b${word}\\b`, 'g');
              temp.innerHTML = temp.innerHTML.replace(regex, `<span class="er" style="color: ${colors.yellow};">${word}</span>`);
              span.innerHTML = temp.innerHTML;
            }
          }
        });
      });
    }
  }

  // Call our enhancement function after a short delay to ensure Quarto has finished processing
  setTimeout(enhanceSyntaxHighlighting, 500);
  
  // Also add a handler for window load to ensure everything is fully loaded
  window.addEventListener('load', function() {
    // Apply again after full load
    setTimeout(enhanceSyntaxHighlighting, 500);
  });
  
  // Handle dynamic content loading or MathJax processing, which could delay rendering
  if (window.MathJax) {
    window.MathJax.Hub.Queue(function() {
      enhanceSyntaxHighlighting();
    });
  }
});

// Reapply styling when the user switches between tabs or panels
document.addEventListener('visibilitychange', function() {
  if (!document.hidden) {
    setTimeout(function() {
      // Function to get all Python code blocks
      const codeBlocks = document.querySelectorAll('code.sourceCode.python');
      if (codeBlocks.length > 0) {
        // If code blocks exist, try re-running the enhancement
        if (typeof enhanceSyntaxHighlighting === 'function') {
          enhanceSyntaxHighlighting();
        }
      }
    }, 500);
  }
}); 