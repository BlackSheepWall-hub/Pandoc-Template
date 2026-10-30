-- Vertically align images that share a paragraph with surrounding text.
-- Standalone images and explicit .image-row groups are handled earlier by
-- image-row.lua and are intentionally left unchanged.

if not FORMAT:match("latex") then
  return {}
end

local inline_image_shift = "-0.20em"

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
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

local function image_to_latex(image)
  local document = pandoc.Pandoc({pandoc.Plain({image})})
  return trim(pandoc.write(document, "latex"))
end

local function align_inline_images(block)
  if standalone_image(block) then
    return nil
  end

  return block:walk({
    Image = function(image)
      return pandoc.RawInline(
        "latex",
        "\\raisebox{" .. inline_image_shift .. "}{" ..
          image_to_latex(image) .. "\\unskip}"
      )
    end,
  })
end

local function read_metadata(meta)
  if meta["inline-image-shift"] then
    inline_image_shift = pandoc.utils.stringify(meta["inline-image-shift"])
  end
end

return {
  { Meta = read_metadata },
  { Para = align_inline_images, Plain = align_inline_images },
}
