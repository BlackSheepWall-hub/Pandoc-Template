-- Preserve the template's boxed inline-code style while allowing code that
-- is wider than a full text line to be split into separately boxed lines.

if not FORMAT:match("latex") then
  return {}
end

local natural_break_after = {
  [" "] = true,
  ["/"] = true,
  ["\\"] = true,
  ["."] = true,
  ["_"] = true,
  ["-"] = true,
  [":"] = true,
  [","] = true,
  [";"] = true,
}

local function code_to_latex(text)
  local document = pandoc.Pandoc({pandoc.Plain({pandoc.Code(text)})})
  local rendered = pandoc.write(document, "latex")
  local content = rendered:match("^\\texttt%{(.*)%}%s*$")

  if not content then
    error("Unable to extract Pandoc's LaTeX representation for inline code")
  end

  return content
end

local function characters(text)
  local result = {}
  for _, codepoint in utf8.codes(text) do
    result[#result + 1] = utf8.char(codepoint)
  end
  return result
end

local function natural_chunks(text)
  local result = {}
  local current = {}

  for _, character in ipairs(characters(text)) do
    current[#current + 1] = character
    if natural_break_after[character] then
      result[#result + 1] = table.concat(current)
      current = {}
    end
  end

  if #current > 0 then
    result[#result + 1] = table.concat(current)
  end

  return result
end

local function render_fallback_characters(chunk)
  local result = {}
  for _, character in ipairs(characters(chunk)) do
    result[#result + 1] =
      "\\HomeworkInlineCodeChar{" .. code_to_latex(character) .. "}"
  end
  return table.concat(result)
end

local function render_chunks(text)
  local result = {}
  for _, chunk in ipairs(natural_chunks(text)) do
    result[#result + 1] =
      "\\HomeworkInlineCodeChunk{" .. code_to_latex(chunk) .. "}{" ..
      render_fallback_characters(chunk) .. "}"
  end
  return table.concat(result)
end

function Code(element)
  local text = element.text
  local latex =
    "\\HomeworkInlineCode{" .. code_to_latex(text) .. "}{" ..
    render_chunks(text) .. "}"
  return pandoc.RawInline("latex", latex)
end
