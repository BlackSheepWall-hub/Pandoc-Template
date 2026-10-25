-- Give standalone images a one-third-line default width and convert an
-- explicit .image-row Div into the homework template's single-row,
-- equal-height image layout. Inline images are untouched.

if not FORMAT:match("latex") then
  return {}
end

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function has_class(element, expected)
  for _, class in ipairs(element.classes) do
    if class == expected then
      return true
    end
  end
  return false
end

local function standalone_image(block)
  if block.t ~= "Plain" and block.t ~= "Para" then
    return nil
  end

  local found = nil
  for _, inline in ipairs(block.content) do
    if inline.t == "Image" then
      if found then
        return nil
      end
      found = inline
    elseif inline.t ~= "Space" and inline.t ~= "SoftBreak" and
           inline.t ~= "LineBreak" then
      return nil
    end
  end

  return found
end

local function apply_default_image_width(image)
  if image and not image.attributes.width then
    image.attributes.width = "33%"
    return true
  end
  return false
end

local function default_width_for_standalone_block(block)
  if apply_default_image_width(standalone_image(block)) then
    return block
  end
  return nil
end

local function inlines_to_latex(inlines)
  if not inlines or #inlines == 0 then
    return ""
  end

  local document = pandoc.Pandoc({pandoc.Plain(inlines)})
  return trim(pandoc.write(document, "latex"))
end

local function blocks_to_latex(blocks)
  if not blocks or #blocks == 0 then
    return ""
  end

  return trim(pandoc.write(pandoc.Pandoc(blocks), "latex"))
end

local function markdown_text_to_latex(text)
  if not text or text == "" then
    return ""
  end

  return blocks_to_latex(pandoc.read(text, "markdown").blocks)
end

local function image_path_to_latex(source)
  local image = pandoc.Image({}, source)
  local rendered = pandoc.write(
    pandoc.Pandoc({pandoc.Plain({image})}),
    "latex"
  )
  local braced_path = rendered:match("\\includegraphics%[[^%]]*%](%b{})")

  if not braced_path then
    error("Unable to convert image path to LaTeX: " .. source)
  end

  return braced_path:sub(2, -2)
end

local function image_item(image, identifier, caption)
  return {
    path = image_path_to_latex(image.src),
    identifier = identifier or image.identifier or "",
    caption = caption or inlines_to_latex(image.caption),
  }
end

local function single_image_from_figure(figure)
  local found = {}

  for _, block in ipairs(figure.content) do
    if block.t == "Plain" or block.t == "Para" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Image" then
          found[#found + 1] = inline
        elseif inline.t ~= "Space" and inline.t ~= "SoftBreak" and
               inline.t ~= "LineBreak" then
          error("An .image-row figure may contain only one image")
        end
      end
    end
  end

  if #found ~= 1 then
    error("An .image-row figure must contain exactly one image")
  end

  local caption = ""
  if figure.caption and figure.caption.long then
    caption = blocks_to_latex(figure.caption.long)
  end

  return image_item(
    found[1],
    figure.identifier ~= "" and figure.identifier or found[1].identifier,
    caption
  )
end

local function collect_items(div)
  local items = {}

  for _, block in ipairs(div.content) do
    if block.t == "Figure" then
      items[#items + 1] = single_image_from_figure(block)
    elseif block.t == "Plain" or block.t == "Para" then
      for _, inline in ipairs(block.content) do
        if inline.t == "Image" then
          items[#items + 1] = image_item(inline)
        elseif inline.t ~= "Space" and inline.t ~= "SoftBreak" and
               inline.t ~= "LineBreak" then
          error("An .image-row may contain only images")
        end
      end
    else
      error("An .image-row may contain only images")
    end
  end

  if #items == 0 then
    error("An .image-row must contain at least one image")
  end

  return items
end

local function item_to_latex(item)
  return table.concat({
    "\\HomeworkImageRowItem{", item.path, "}{",
    item.identifier, "}{", item.caption, "}"
  })
end

function Div(element)
  if not has_class(element, "image-row") then
    return nil
  end

  local attributes = element.attributes
  local items = collect_items(element)
  local rendered_items = {}

  for _, item in ipairs(items) do
    rendered_items[#rendered_items + 1] = item_to_latex(item)
  end

  local latex = table.concat({
    "\\HomeworkImageRow{",
    attributes.scale or "",
    "}{",
    attributes["gap-ratio"] or "",
    "}{",
    attributes["max-height"] or "",
    "}{",
    element.identifier or "",
    "}{",
    markdown_text_to_latex(attributes.caption or ""),
    "}{\n",
    table.concat(rendered_items, "\n"),
    "\n}"
  })

  return pandoc.RawBlock("latex", latex)
end

function Figure(element)
  local found = nil

  for _, block in ipairs(element.content) do
    local image = standalone_image(block)
    if image then
      if found then
        return nil
      end
      found = image
    end
  end

  if apply_default_image_width(found) then
    return element
  end
  return nil
end

function Para(element)
  return default_width_for_standalone_block(element)
end

function Plain(element)
  return default_width_for_standalone_block(element)
end
