-- Keep compact tables at their natural width and give every genuinely wide
-- table content-aware, wrappable columns.  Pandoc's --columns decision is
-- retained for compatibility, but it is no longer the gate: every table is
-- measured here, including tables for which Pandoc emitted natural columns.

if not FORMAT:match("latex") then
  return {}
end

local configured_budget = nil
local landscape_budget = 112
local minimum_wrapped_column_width = 6
local maximum_unbroken_text_width = 12
local emergency_break_safety = 0.8
local header_line_target = 2
local body_line_target = 3
local overflow_policy = "landscape"
local overflow_failure = "error"
local measured_table_counter = 0
local default_image_width_marker = "data-homework-default-width"

local natural_break_after = {
  ["/"] = true,
  ["\\"] = true,
  ["."] = true,
  ["_"] = true,
  ["-"] = true,
  [":"] = true,
  ["?"] = true,
  ["&"] = true,
  ["="] = true,
  ["#"] = true,
  [","] = true,
  [";"] = true,
}

local function in_range(value, first, last)
  return value >= first and value <= last
end

local function is_wide_codepoint(codepoint)
  return in_range(codepoint, 0x1100, 0x115F)
    or in_range(codepoint, 0x2329, 0x232A)
    or in_range(codepoint, 0x2E80, 0xA4CF)
    or in_range(codepoint, 0xAC00, 0xD7A3)
    or in_range(codepoint, 0xF900, 0xFAFF)
    or in_range(codepoint, 0xFE10, 0xFE19)
    or in_range(codepoint, 0xFE30, 0xFE6F)
    or in_range(codepoint, 0xFF01, 0xFF60)
    or in_range(codepoint, 0xFFE0, 0xFFE6)
    or in_range(codepoint, 0x1F300, 0x1FAFF)
    or in_range(codepoint, 0x20000, 0x3FFFD)
end

local function codepoint_width(codepoint)
  if in_range(codepoint, 0x0300, 0x036F)
      or in_range(codepoint, 0x1AB0, 0x1AFF)
      or in_range(codepoint, 0x1DC0, 0x1DFF)
      or in_range(codepoint, 0x20D0, 0x20FF)
      or in_range(codepoint, 0xFE20, 0xFE2F) then
    return 0
  end

  if is_wide_codepoint(codepoint) then
    return 2
  end

  return 1
end

local function character_width(character)
  local codepoint = utf8.codepoint(character)
  return codepoint and codepoint_width(codepoint) or 0
end

local function characters(text)
  local result = {}
  for _, codepoint in utf8.codes(text) do
    result[#result + 1] = utf8.char(codepoint)
  end
  return result
end

local function display_width(text)
  local widest = 0
  for line in (text .. "\n"):gmatch("(.-)\n") do
    local width = 0
    line = line:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    for _, codepoint in utf8.codes(line) do
      width = width + codepoint_width(codepoint)
    end
    widest = math.max(widest, width)
  end
  return widest
end

local function longest_text_segment(text)
  local longest = 0
  local current = 0

  for _, character in ipairs(characters(text)) do
    local codepoint = utf8.codepoint(character)
    if character:match("%s") then
      current = 0
    elseif is_wide_codepoint(codepoint) then
      -- XeTeX can naturally break CJK text between characters.
      longest = math.max(longest, current, codepoint_width(codepoint))
      current = 0
    else
      current = current + codepoint_width(codepoint)
      longest = math.max(longest, current)
      if natural_break_after[character] then
        current = 0
      end
    end
  end

  return longest
end

local function cell_atomic_width(cell)
  local widest = 1
  local filter = {
    Str = function(element)
      widest = math.max(
        widest,
        math.min(longest_text_segment(element.text), maximum_unbroken_text_width)
      )
    end,
    Code = function(_)
      -- inline-code.lua already provides punctuation and character fallbacks.
      widest = math.max(widest, 1)
    end,
    Math = function(_)
      -- Formula source length is not a reliable physical width.  Formula
      -- tables are measured by TeX before their column widths are fixed.
    end,
  }

  for _, block in ipairs(cell.contents) do
    pandoc.walk_block(block, filter)
  end
  return widest
end

local function table_label(table_element)
  local caption = pandoc.utils.stringify(table_element.caption)
  if caption and caption ~= "" then
    return "table '" .. caption .. "'"
  end
  return "an uncaptained table"
end

local function sum_widths(widths)
  local total = 0
  for _, width in ipairs(widths) do
    total = total + width
  end
  return total
end

local function ensure_span_width(widths, first, last, required)
  local current = 0
  for index = first, last do
    current = current + widths[index]
  end

  local missing = required - current
  local index = first
  while missing > 0 and first <= last do
    widths[index] = widths[index] + 1
    missing = missing - 1
    index = index + 1
    if index > last then
      index = first
    end
  end
end

local function add_natural_rows(rows, widths)
  for _, row in ipairs(rows) do
    local column = 1
    for _, cell in ipairs(row.cells) do
      local span = math.max(1, cell.col_span or 1)
      local last = math.min(#widths, column + span - 1)
      ensure_span_width(
        widths,
        column,
        last,
        display_width(pandoc.utils.stringify(cell.contents))
      )
      column = column + span
    end
  end
end

local function measured_column_widths(table_element)
  local widths = {}
  for index = 1, #table_element.colspecs do
    widths[index] = 1
  end

  add_natural_rows(table_element.head.rows, widths)
  for _, body in ipairs(table_element.bodies) do
    add_natural_rows(body.head, widths)
    add_natural_rows(body.body, widths)
  end
  add_natural_rows(table_element.foot.rows, widths)
  return widths
end

local function table_overhead(column_count)
  -- Compatibility estimate: roughly two text columns of padding per table
  -- column and one for each vertical rule, including the outer borders.
  return 2 * column_count + (column_count + 1)
end

local function natural_table_width(table_element)
  local widths = measured_column_widths(table_element)
  return sum_widths(widths) + table_overhead(#widths)
end

local function table_has_image(table_element)
  local found = false
  local function inspect_rows(rows)
    for _, row in ipairs(rows) do
      for _, cell in ipairs(row.cells) do
        for _, block in ipairs(cell.contents) do
          pandoc.walk_block(block, {
            Image = function(_)
              found = true
            end,
          })
        end
      end
    end
  end

  inspect_rows(table_element.head.rows)
  for _, body in ipairs(table_element.bodies) do
    inspect_rows(body.head)
    inspect_rows(body.body)
  end
  inspect_rows(table_element.foot.rows)
  return found
end

local function cell_width_requirements(cell, line_target)
  local natural = display_width(pandoc.utils.stringify(cell.contents))
  if natural <= 0 then
    return 1, 1
  end

  local hard_minimum = math.max(
    1,
    math.min(natural, cell_atomic_width(cell))
  )
  local preferred = math.min(
    natural,
    math.max(
      minimum_wrapped_column_width,
      hard_minimum,
      math.ceil(natural / line_target) + 1
    )
  )
  return preferred, hard_minimum
end

local function add_wrapped_rows(rows, preferred, minimums, line_target)
  for _, row in ipairs(rows) do
    local column = 1
    for _, cell in ipairs(row.cells) do
      local span = math.max(1, cell.col_span or 1)
      local last = math.min(#preferred, column + span - 1)
      local required, hard_minimum = cell_width_requirements(cell, line_target)
      ensure_span_width(minimums, column, last, hard_minimum)
      ensure_span_width(preferred, column, last, required)
      column = column + span
    end
  end
end

local function wrapped_column_widths(table_element)
  local preferred = {}
  local minimums = {}
  for index = 1, #table_element.colspecs do
    preferred[index] = minimum_wrapped_column_width
    minimums[index] = minimum_wrapped_column_width
  end

  add_wrapped_rows(
    table_element.head.rows,
    preferred,
    minimums,
    header_line_target
  )
  for _, body in ipairs(table_element.bodies) do
    add_wrapped_rows(body.head, preferred, minimums, header_line_target)
    add_wrapped_rows(body.body, preferred, minimums, body_line_target)
  end
  add_wrapped_rows(
    table_element.foot.rows,
    preferred,
    minimums,
    body_line_target
  )

  for index, minimum in ipairs(minimums) do
    preferred[index] = math.max(preferred[index], minimum)
  end
  return preferred, minimums
end

local function copy_widths(widths)
  local result = {}
  for index, width in ipairs(widths) do
    result[index] = width
  end
  return result
end

local function fit_widths_to_budget(widths, minimums, content_budget)
  local total = sum_widths(widths)
  while total > content_budget do
    local selected = nil
    local greatest_reducible = 0
    for index, width in ipairs(widths) do
      local reducible = width - minimums[index]
      if reducible > greatest_reducible then
        greatest_reducible = reducible
        selected = index
      end
    end

    if not selected then
      return widths, false
    end
    widths[selected] = widths[selected] - 1
    total = total - 1
  end

  return widths, true
end

local function append_text(result, buffer)
  if #buffer > 0 then
    result[#result + 1] = pandoc.Str(table.concat(buffer))
    for index = #buffer, 1, -1 do
      buffer[index] = nil
    end
  end
end

local function break_long_string(element, limit)
  -- The allocation budget uses mixed CJK display columns.  Latin capitals and
  -- punctuation are often wider than one half of a CJK em in the actual font,
  -- so use a conservative limit when placing emergency break opportunities.
  limit = math.max(1, math.floor(limit * emergency_break_safety))
  if display_width(element.text) <= limit then
    return nil
  end

  local result = {}
  local buffer = {}
  local segment_width = 0

  for _, character in ipairs(characters(element.text)) do
    local codepoint = utf8.codepoint(character)
    local width = character_width(character)

    if is_wide_codepoint(codepoint) then
      buffer[#buffer + 1] = character
      segment_width = 0
    else
      if segment_width > 0 and segment_width + width > limit then
        append_text(result, buffer)
        result[#result + 1] = pandoc.RawInline("latex", "\\allowbreak{}")
        segment_width = 0
      end

      buffer[#buffer + 1] = character
      segment_width = segment_width + width
      if natural_break_after[character] then
        append_text(result, buffer)
        result[#result + 1] = pandoc.RawInline("latex", "\\allowbreak{}")
        segment_width = 0
      end
    end
  end

  append_text(result, buffer)
  return result
end

local function add_cell_breaks(cell, limit)
  local filter = {
    Str = function(element)
      return break_long_string(element, limit)
    end,
  }

  for index, block in ipairs(cell.contents) do
    cell.contents[index] = pandoc.walk_block(block, filter)
  end
end

local function add_row_breaks(rows, widths)
  for _, row in ipairs(rows) do
    local column = 1
    for _, cell in ipairs(row.cells) do
      local span = math.max(1, cell.col_span or 1)
      local last = math.min(#widths, column + span - 1)
      local available = 0
      for index = column, last do
        available = available + widths[index]
      end
      add_cell_breaks(cell, math.max(1, available))
      column = column + span
    end
  end
end

local function add_table_breaks(table_element, widths)
  add_row_breaks(table_element.head.rows, widths)
  for _, body in ipairs(table_element.bodies) do
    add_row_breaks(body.head, widths)
    add_row_breaks(body.body, widths)
  end
  add_row_breaks(table_element.foot.rows, widths)
end

local function inline_to_latex(element)
  local document = pandoc.Pandoc({pandoc.Plain({element})})
  return pandoc.write(document, "latex"):gsub("%s+$", "")
end

local function math_to_latex(element)
  if element.mathtype == "DisplayMath" then
    return "\\(\\displaystyle " .. element.text .. "\\)"
  end
  return "\\(" .. element.text .. "\\)"
end

local function code_content_to_latex(text)
  local rendered = inline_to_latex(pandoc.Code(text))
  local content = rendered:match("^\\texttt%{(.*)%}$")
  if not content then
    error("[table-width] unable to measure code content in LaTeX")
  end
  return content
end

local function ordinary_text_block_to_latex(block)
  if block.t ~= "Plain" and block.t ~= "Para" then
    return nil
  end

  local found_text = false
  local wrapped = pandoc.walk_block(block, {
    Str = function(_)
      found_text = true
    end,
    Math = function(_)
      return {}
    end,
    Image = function(_)
      return {}
    end,
    Code = function(_)
      return {}
    end,
    RawInline = function(element)
      if element.format:match("latex")
          and element.text == "\\allowbreak{}" then
        return element
      end
      return {}
    end,
    Note = function(_)
      return {}
    end,
  })

  if not found_text then
    return nil
  end

  local natural = pandoc.walk_block(block, {
    Code = function(element)
      return pandoc.RawInline(
        "latex",
        "\\HomeworkInlineCodeBox{" .. code_content_to_latex(element.text) .. "}"
      )
    end,
    RawInline = function(element)
      if element.format:match("latex")
          and element.text == "\\allowbreak{}" then
        return element
      end
      -- Raw LaTeX has its own measured constraint. Keeping it out of this
      -- combined line avoids executing arbitrary commands inside an hbox.
      return {}
    end,
    Note = function(_)
      return {}
    end,
  })

  local wrapped_latex =
    pandoc.write(pandoc.Pandoc({wrapped}), "latex"):gsub("%s+$", "")
  local natural_latex =
    pandoc.write(pandoc.Pandoc({natural}), "latex"):gsub("%s+$", "")
  return wrapped_latex, natural_latex
end

local function raw_latex_is_structural(text)
  return text:match("\\begin%s*%{")
    or text:match("\\end%s*%{")
    or text:match("\\par%f[%A]")
    or text:match("\\%[")
end

local function assert_measurable_raw_latex(text)
  if raw_latex_is_structural(text) then
    error(
      "[table-width] structural Raw LaTeX inside a table cell cannot be " ..
      "measured safely; replace it with normal Markdown or split the table"
    )
  end
end

local function collect_code_measurement(
    codes,
    column,
    span,
    inline,
    text
  )
  codes[#codes + 1] = {
    column = column,
    span = span,
    inline = inline,
    latex = code_content_to_latex(text),
  }
end

local function collect_row_measurements(
    rows,
    texts,
    formulas,
    graphics,
    raw_latex,
    codes,
    line_target
  )
  for _, row in ipairs(rows) do
    local column = 1
    for _, cell in ipairs(row.cells) do
      local span = math.max(1, cell.col_span or 1)
      for index, block in ipairs(cell.contents) do
        local ordinary_latex, natural_latex =
          ordinary_text_block_to_latex(block)
        if ordinary_latex and ordinary_latex ~= "" then
          texts[#texts + 1] = {
            column = column,
            span = span,
            line_target = line_target,
            latex = ordinary_latex,
            natural_latex = natural_latex,
          }
        end
        if block.t == "RawBlock" and block.format:match("latex") then
          assert_measurable_raw_latex(block.text)
          raw_latex[#raw_latex + 1] = {
            column = column,
            span = span,
            latex = block.text,
          }
          -- A non-structural RawBlock is semantically inline content placed
          -- in its own paragraph.  Converting it lets the normal cell guard
          -- and width checks handle it consistently.
          cell.contents[index] = pandoc.Plain({
            pandoc.RawInline("latex", block.text),
          })
        else
          if block.t == "CodeBlock" then
            local found_line = false
            for line in (block.text .. "\n"):gmatch("(.-)\n") do
              if line ~= "" then
                found_line = true
                collect_code_measurement(
                  codes,
                  column,
                  span,
                  false,
                  line
                )
              end
            end
            if not found_line then
              collect_code_measurement(
                codes,
                column,
                span,
                false,
                " "
              )
            end
          end
          cell.contents[index] = pandoc.walk_block(block, {
          Math = function(element)
            formulas[#formulas + 1] = {
              column = column,
              span = span,
              latex = math_to_latex(element),
            }
          end,
          Image = function(element)
            local automatic_width = not element.attributes.width
              or element.attributes[default_image_width_marker] ~= nil
            if element.attributes[default_image_width_marker] then
              element.attributes.width = nil
              element.attributes[default_image_width_marker] = nil
            end
            graphics[#graphics + 1] = {
              column = column,
              span = span,
              automatic_width = automatic_width,
              latex = inline_to_latex(element),
            }
            return element
          end,
          RawInline = function(element)
            if not element.format:match("latex")
                or element.text == "\\allowbreak{}" then
              return nil
            end
            assert_measurable_raw_latex(element.text)
            raw_latex[#raw_latex + 1] = {
              column = column,
              span = span,
              latex = element.text,
            }
          end,
          Code = function(element)
            collect_code_measurement(
              codes,
              column,
              span,
              true,
              element.text
            )
          end,
          })
        end
      end
      column = column + span
    end
  end
end

local function collect_table_measurements(table_element)
  local texts = {}
  local formulas = {}
  local graphics = {}
  local raw_latex = {}
  local codes = {}
  collect_row_measurements(
    table_element.head.rows,
    texts,
    formulas,
    graphics,
    raw_latex,
    codes,
    header_line_target
  )
  for _, body in ipairs(table_element.bodies) do
    collect_row_measurements(
      body.head,
      texts,
      formulas,
      graphics,
      raw_latex,
      codes,
      header_line_target
    )
    collect_row_measurements(
      body.body,
      texts,
      formulas,
      graphics,
      raw_latex,
      codes,
      body_line_target
    )
  end
  collect_row_measurements(
    table_element.foot.rows,
    texts,
    formulas,
    graphics,
    raw_latex,
    codes,
    body_line_target
  )
  return texts, formulas, graphics, raw_latex, codes
end

local function join_numbers(values)
  local result = {}
  for index, value in ipairs(values) do
    result[index] = tostring(value)
  end
  return table.concat(result, ",")
end

local function measured_table_plan(
    table_id,
    portrait_budget,
    landscape_content_budget,
    preferred,
    minimums,
    texts,
    formulas,
    graphics,
    raw_latex,
    codes
  )
  local measurements = {}
  for _, ordinary in ipairs(texts) do
    measurements[#measurements + 1] = string.format(
      "\\HomeworkMeasureTableText{%d}{%d}{%d}{%s}{%s}",
      ordinary.column,
      ordinary.span,
      ordinary.line_target,
      ordinary.natural_latex,
      ordinary.latex
    )
  end
  for _, formula in ipairs(formulas) do
    measurements[#measurements + 1] = string.format(
      "\\HomeworkMeasureTableFormula{%d}{%d}{%s}",
      formula.column,
      formula.span,
      formula.latex
    )
  end
  for _, graphic in ipairs(graphics) do
    measurements[#measurements + 1] = string.format(
      "\\HomeworkMeasureTableGraphic{%d}{%d}{%d}{%s}",
      graphic.column,
      graphic.span,
      graphic.automatic_width and 1 or 0,
      graphic.latex
    )
  end
  for _, raw in ipairs(raw_latex) do
    measurements[#measurements + 1] = string.format(
      "\\HomeworkMeasureTableRaw{%d}{%d}{%s}",
      raw.column,
      raw.span,
      raw.latex
    )
  end
  for _, code in ipairs(codes) do
    measurements[#measurements + 1] = string.format(
      "\\HomeworkMeasureTableCode{%d}{%d}{%d}{%s}",
      code.column,
      code.span,
      code.inline and 1 or 0,
      code.latex
    )
  end

  return string.format(
    "\\HomeworkPrepareMeasuredTable{%d}{%d}{%d}{%s}{%s}{%d}{%s}",
    table_id,
    portrait_budget,
    landscape_content_budget,
    join_numbers(preferred),
    join_numbers(minimums),
    1,
    table.concat(measurements)
  )
end

local function guard_cell_atoms(cell)
  local filter = {
    Math = function(element)
      local content
      if element.mathtype == "DisplayMath" then
        content = "\\(\\displaystyle " .. element.text .. "\\)"
      else
        content = "\\(" .. element.text .. "\\)"
      end
      return pandoc.RawInline(
        "latex",
        "\\HomeworkFitCellMath{" .. content .. "}"
      )
    end,
    Image = function(element)
      return pandoc.RawInline(
        "latex",
        "\\HomeworkFitCellGraphic{" .. inline_to_latex(element) .. "}"
      )
    end,
    RawInline = function(element)
      if not element.format:match("latex")
          or element.text == "\\allowbreak{}" then
        return nil
      end
      assert_measurable_raw_latex(element.text)
      return pandoc.RawInline(
        "latex",
        "\\HomeworkFitCellRaw{" .. element.text .. "}"
      )
    end,
  }

  for index, block in ipairs(cell.contents) do
    if block.t == "RawBlock" and block.format:match("latex") then
      assert_measurable_raw_latex(block.text)
    end
    cell.contents[index] = pandoc.walk_block(block, filter)
  end
end

local function guard_row_atoms(rows)
  for _, row in ipairs(rows) do
    for _, cell in ipairs(row.cells) do
      guard_cell_atoms(cell)
    end
  end
end

local function guard_table_atoms(table_element)
  guard_row_atoms(table_element.head.rows)
  for _, body in ipairs(table_element.bodies) do
    guard_row_atoms(body.head)
    guard_row_atoms(body.body)
  end
  guard_row_atoms(table_element.foot.rows)
end

local function read_positive_number(metadata, key, fallback)
  local value = metadata[key]
  if not value then
    return fallback
  end
  local parsed = tonumber(pandoc.utils.stringify(value))
  if parsed and parsed > 0 then
    return parsed
  end
  return fallback
end

local function read_metadata(metadata)
  configured_budget = read_positive_number(
    metadata,
    "table-natural-width-columns",
    configured_budget
  )
  maximum_unbroken_text_width = read_positive_number(
    metadata,
    "table-unbreakable-text-columns",
    maximum_unbroken_text_width
  )
  minimum_wrapped_column_width = read_positive_number(
    metadata,
    "table-min-readable-columns",
    minimum_wrapped_column_width
  )
  landscape_budget = read_positive_number(
    metadata,
    "table-landscape-width-columns",
    landscape_budget
  )

  if metadata["table-overflow-policy"] then
    overflow_policy = pandoc.utils.stringify(metadata["table-overflow-policy"])
  end
  if metadata["table-overflow-failure"] then
    overflow_failure = pandoc.utils.stringify(metadata["table-overflow-failure"])
  end
  return metadata
end

local function clear_column_widths(table_element)
  for _, colspec in ipairs(table_element.colspecs) do
    colspec[2] = nil
  end
end

local function adjust_table_width(table_element)
  local budget = configured_budget
    or math.floor((PANDOC_WRITER_OPTIONS.columns or 60) * 1.2)
  local column_count = #table_element.colspecs
  local content_budget = math.max(
    column_count,
    budget - table_overhead(column_count)
  )
  local landscape_content_budget = math.max(
    column_count,
    landscape_budget - table_overhead(column_count)
  )
  local _, minimums = wrapped_column_widths(table_element)

  -- Invisible emergency opportunities are inserted before serialization so
  -- TeX's trial paragraphs see the same breakability as the final cells.
  add_table_breaks(table_element, minimums)
  local texts, formulas, graphics, raw_latex, codes =
    collect_table_measurements(table_element)
  guard_table_atoms(table_element)

  -- Non-nil fractions make Pandoc emit p-columns.  The template replaces
  -- their provisional sizes with exact dimensions measured before longtable.
  for _, colspec in ipairs(table_element.colspecs) do
    colspec[2] = 1 / column_count
  end

  measured_table_counter = measured_table_counter + 1
  return {
    pandoc.RawBlock(
      "latex",
      measured_table_plan(
        measured_table_counter,
        content_budget,
        landscape_content_budget,
        minimums,
        minimums,
        texts,
        formulas,
        graphics,
        raw_latex,
        codes
      )
    ),
    table_element,
    pandoc.RawBlock("latex", "\\HomeworkFinishMeasuredTable"),
  }
end

local function clear_default_image_width_marker(element)
  element.attributes[default_image_width_marker] = nil
  return element
end

return {
  { Meta = read_metadata },
  { Table = adjust_table_width },
  { Image = clear_default_image_width_marker },
}
