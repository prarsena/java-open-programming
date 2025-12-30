-- code_filter.lua
-- This script processes Pandoc AST elements to:
-- 1. Trim leading/trailing whitespace from text.
-- 2. Normalize common "smart" Unicode characters to their ASCII equivalents.
-- 3. Remove HTML comments (both block and inline).
-- 4. Transform Java code blocks into a specific Brightspace D2L format.

-- Helper function to trim leading/trailing whitespace (including newlines)
local function trim(s)
  if s == nil then return "" end
  -- %s* matches zero or more whitespace characters
  -- (.*%S) captures content that has at least one non-whitespace character, followed by %S (last non-whitespace)
  -- %s*$ matches zero or more whitespace characters to the end of the string
  -- The 'or ""' handles cases where the string might be entirely whitespace
  return s:match("^%s*(.*%S)%s*$") or ""
end

-- Function to normalize common "odd" characters in strings
function normalize_string(s)
  if s == nil then return "" end

  -- Replace non-breaking space (U+00A0) with standard space (U+0020)
  -- \xC2\xA0 is the UTF-8 byte sequence for U+00A0
  s = s:gsub("\xC2\xA0", " ")

  -- Replace smart quotes and apostrophes with straight equivalents
  -- U+2018 Left single quotation mark
  -- U+2019 Right single quotation mark (apostrophe)
  -- U+201C Left double quotation mark
  -- U+201D Right double quotation mark
  s = s:gsub("\xE2\x80\x98", "'")
  s = s:gsub("\xE2\x80\x99", "'")
  s = s:gsub("\xE2\x80\x9C", '"')
  s = s:gsub("\xE2\x80\x9D", '"')

  -- Replace en dash (U+2013) and em dash (U+2014) with hyphen (U+002D) or double hyphen
  -- U+2013 En Dash
  -- U+2014 Em Dash
  s = s:gsub("\xE2\x80\x93", "-")
  s = s:gsub("\xE2\x80\x94", "--")

  -- Replace ellipsis (U+2026) with three periods
  -- U+2026 Horizontal Ellipsis
  s = s:gsub("\xE2\x80\xA6", "...")

  return s
end

-- Function to fix HTML entities back to normal characters
function fix_html_entities(s)
  if s == nil then return "" end
  
  -- Convert common HTML entities back to normal characters
  s = s:gsub("&quot;", '"')
  s = s:gsub("&apos;", "'")
  s = s:gsub("&amp;", "&")
  s = s:gsub("&lt;", "<")
  s = s:gsub("&gt;", ">")
  
  return s
end

-- Filter function for regular strings (Str elements)
-- This function is applied to all plain text nodes in the document.
function Str(elem)
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: Str detected. Content (before): '" .. elem.text .. "'\n")
  elem.text = normalize_string(elem.text)
  -- io.stderr:write("DEBUG: Str detected. Content (after): '" .. elem.text .. "'\n")
  return elem -- Return the modified element to keep it in the document
end

-- Filter function for RawBlock elements (e.g., block-level HTML embedded in Markdown)
function RawBlock(elem)
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: RawBlock detected. Format: " .. elem.format .. "\n")
  -- io.stderr:write("DEBUG: RawBlock content (start):\n" .. elem.text .. "\nDEBUG: RawBlock content (end)\n")

  if elem.format == 'html' then
    -- Pattern to match HTML comments: -- ^%s* : Matches start of string, ignoring leading whitespace.
    -- : Literal match for comment closing tag.
    -- %s*$ : Matches trailing whitespace, ignoring to end of string.
    if elem.text:match("^%s*%s*$") then
      -- Uncomment for debugging:
      -- io.stderr:write("DEBUG: Matched HTML comment RawBlock - Removing.\n")
      return {} -- Return an empty table to remove this element from the AST
    end
  end
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: RawBlock not removed - returning original.\n")
  return nil -- Return nil to let Pandoc's default writer handle other RawBlocks
end

-- Filter function for RawInline elements (e.g., inline HTML embedded in Markdown)
function RawInline(elem)
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: RawInline detected. Format: " .. elem.format .. "\n")
  -- io.stderr:write("DEBUG: RawInline content: '" .. elem.text .. "'\n")

  if elem.format == 'html' then
    -- Same pattern as RawBlock for HTML comments
    if elem.text:match("^%s*%s*$") then
      -- Uncomment for debugging:
      -- io.stderr:write("DEBUG: Matched HTML comment RawInline - Removing.\n")
      return {} -- Return an empty table to remove this element from the AST
    end
  end
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: RawInline not removed - returning original.\n")
  return nil -- Return nil to let Pandoc's default writer handle other RawInlines
end

-- Filter function for CodeBlock elements (fenced code blocks like ```java)
function CodeBlock(elem)
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: CodeBlock detected. Classes: ")
  -- if elem.classes then
  --   for i, class in ipairs(elem.classes) do
  --     io.stderr:write(class .. " ")
  --   end
  -- end
  -- io.stderr:write("\n")
  -- io.stderr:write("DEBUG: CodeBlock content (start):\n" .. elem.text .. "\nDEBUG: CodeBlock content (end)\n")

  local accepted_langs = {
    ["java"] = true,
    ["bash"] = true,
    ["python"] = true,
    ["javascript"] = true,
    ["armasm"] = true,
    ["cpp"] = true,
    ["c"] = true,
    ["json"] = true
  }

  -- Check if the code block has at least one class (language identifier)
  if elem.classes and #elem.classes > 0 then
    local lang = elem.classes[1] -- The first class is assumed to be the language (e.g., "java", "bash")

    -- Check if it's a supported language for D2L transformation
    if accepted_langs[lang] then
      local trimmed_code_text = trim(elem.text)
      -- Apply character normalization to the code content itself
      trimmed_code_text = normalize_string(trimmed_code_text)

      -- Construct the desired HTML structure for Brightspace D2L
      -- The '\n' ensures the code starts on a new line within the <pre> tag for line numbering scripts.
      local html_output = '<pre class="line-numbers d2l-code"><code class="language-' .. lang .. '">'
      html_output = html_output .. trimmed_code_text .. '\n' -- Add the processed code content
      html_output = html_output .. '</code></pre>'

      -- Uncomment for debugging:
      -- io.stderr:write("DEBUG: Transformed " .. lang .. " CodeBlock to custom D2L format.\n")
      -- Return a RawBlock element, telling Pandoc to insert this raw HTML directly
      return pandoc.RawBlock('html', html_output)
    end
  end
  -- Uncomment for debugging:
  -- io.stderr:write("DEBUG: CodeBlock not transformed - returning original.\n")
  -- Return nil to let Pandoc's default writer handle other CodeBlocks (e.g., Python, C++)
  return nil
end

-- Global variable to track if we've added the HTML wrapper
local html_wrapper_added = false

-- Function to create the complete HTML document with head and body
function Pandoc(doc)
  -- Only add the wrapper once per document
  if not html_wrapper_added then
    html_wrapper_added = true
    
    -- Create the HTML head with all our styles
    local html_head = [[<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="https://s.brightspace.com/lib/fonts/0.6.1/fonts.css">
<link rel="stylesheet" href="https://templates.lcs.brightspace.com/lib/assets/css/styles.min.css">
<style>
/* Table styling */
table {
  border-collapse: collapse;
  width: 100%;
  margin: 1em 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  border-radius: 8px;
  overflow: hidden;
}
table th, table td {
  border: 1px solid #e8e9ea;
  padding: 12px 16px;
  text-align: left;
}
table th {
  background: #764ba2;
  font-weight: 600;
  color: #ffffff;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-size: 0.9em;
}
table tr:nth-child(even) {
  background-color: #f8f9ff;
}
table tr:nth-child(odd) {
  background-color: #ffffff;
}
table tr:hover {
  background: linear-gradient(90deg, #e8f4f8 0%, #d1ecf1 100%);
  transform: scale(1.01);
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Blockquote styling */
blockquote {
  background-color: #fef9e7;
  border-left: 4px solid #007bff;
  margin: 1.5em 0;
  padding: 1em 1.5em;
  font-style: italic;
  color: #5d4e37;
  border-radius: 0 4px 4px 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}
blockquote p {
  margin: 0.5em 0;
}
blockquote p:first-child {
  margin-top: 0;
}
blockquote p:last-child {
  margin-bottom: 0;
}

/* Modern heading styles */
h1 {
  color: #2c3e50;
  font-weight: 700;
  margin-top: 2em;
  margin-bottom: 1em;
  padding-bottom: 0.3em;
  margin-block: 12px 0px !important;
}
h2 {
  color: #34495e;
  font-weight: 600;
  margin-top: 1.8em;
  margin-bottom: 0.8em;
  padding-bottom: 0.2em;
  border-bottom: 1px solid #bdc3c7;
}
h3 {
  color: #34495e;
  font-weight: 600;
  margin-top: 1.5em;
  margin-bottom: 0.75em;
}
h4 {
  color: #34495e;
  font-weight: 600;
  margin-top: 1.3em;
  margin-bottom: 0.7em;
}
h5 {
  color: #7f8c8d;
  font-weight: 500;
  margin-top: 1.2em;
  margin-bottom: 0.6em;
  font-size: 1.1em;
}
h6 {
  color: #95a5a6;
  font-weight: 500;
  margin-top: 1.1em;
  margin-bottom: 0.5em;
  font-size: 1em;
  /* text-transform: uppercase; */
  letter-spacing: 0.5px;
}

/* Inline code styling */
code {
  /* color: #6f42c1 !important; */
  color: #000000 !important; 
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
  font-size: 0.9em;
}

/* More specific selector to override Brightspace styling */
body code {
  /*color: #6f42c1 !important;*/
  color: #000000 !important; 
}

/* Ultra-specific selectors for nested list code - nuclear approach */
html body ul li ul li code {
  color: #000000 !important;
  background-color: transparent !important;
}

html body ul li code {
  color: #000000 !important;
  background-color: transparent !important;
}

/* Catch all possible nested list structures */
body ul li ul li code,
body ol li ul li code,
body ul li ol li code,
body ol li ol li code {
  color: #000000 !important;
  background-color: transparent !important;
}

/* Maximum specificity - this should override everything */
html body:not(.template-fallback) ul li ul li code,
html body:not(.template-fallback) ol li ul li code,
html body:not(.template-fallback) ul li ol li code,
html body:not(.template-fallback) ol li ol li code {
  color: #000000 !important;
  background-color: transparent !important;
}

/* Fallback with ID-level specificity simulation */
html body div ul li ul li code,
html body div ol li ul li code,
html body div ul li ol li code,
html body div ol li ol li code {
  color: #000000 !important;
  background-color: transparent !important;
}

/* Nuclear option - reset ALL possible color-affecting properties */
html body ul li code,
html body ol li code,
html body ul li ul li code,
html body ul li ol li code,
html body ol li ul li code,
html body ol li ol li code {
  color: #000000 !important;
  background-color: transparent !important;
  text-decoration: none !important;
  text-shadow: none !important;
  border: none !important;
  box-shadow: none !important;
  outline: none !important;
  filter: none !important;
  opacity: 1 !important;
}


/* Override for code inside pre blocks (don't apply inline styling to code blocks) */
pre code {
  background-color: transparent;
  color: inherit;
  padding: 0;
  border-radius: 0;
  border: none;
}

/* Add extra spacing after all code blocks */
pre {
  margin-bottom: 2em !important;
}

/* Add extra spacing before all headings H2-H6 */
h2, h3, h4, h5, h6 {
  margin-top: 2em !important;
}
</style>
</head>
<body style="color: rgb(32, 33, 34); font-family: 'Lato', sans-serif; font-size: 12px;">]]
    
    local html_footer = [[</body>
</html>]]
    
    -- Insert the HTML head at the beginning and footer at the end
    table.insert(doc.blocks, 1, pandoc.RawBlock('html', html_head))
    table.insert(doc.blocks, pandoc.RawBlock('html', html_footer))
    
    return doc
  end
  
  return nil -- Let Pandoc handle normally if wrapper already added
end