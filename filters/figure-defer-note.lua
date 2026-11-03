-- Mark the source and final placement pages of ordinary LaTeX figures.
-- The template compares the two marks on a later TeX pass and prints a
-- notice only when a float has moved to a subsequent page.

if not FORMAT:match("latex") then
  return {}
end

local figure_index = 0
local table_figure_marker = "data-homework-inside-table"

local function mark_figures_inside_table(table_element)
  return table_element:walk({
    Figure = function(figure)
      figure.attributes[table_figure_marker] = "true"
      return figure
    end,
  })
end

local function mark_deferred_figure(figure)
  -- Table figures belong entirely to the table layout system.  Remove the
  -- internal marker and leave their sizing, measurement, and rendering
  -- untouched.
  if figure.attributes[table_figure_marker] then
    figure.attributes[table_figure_marker] = nil
    return figure
  end

  figure_index = figure_index + 1
  local identifier = string.format("%06d", figure_index)
  local placement_marker =
    "\\HomeworkDeferredFigurePlaced{" .. identifier .. "}"
  local marker_inserted = false

  -- Keep the marker inline with the image.  Adding a separate block to a
  -- Figure makes Pandoc treat the content as a multi-block figure and changes
  -- the generated layout to multiple minipages.
  for _, block in ipairs(figure.content) do
    if block.t == "Plain" or block.t == "Para" then
      table.insert(
        block.content,
        1,
        pandoc.RawInline("latex", placement_marker)
      )
      marker_inserted = true
      break
    end
  end

  if not marker_inserted then
    table.insert(
      figure.content,
      1,
      pandoc.RawBlock("latex", placement_marker)
    )
  end

  return pandoc.List({
    pandoc.RawBlock(
      "latex",
      "\\HomeworkDeferredFigureSource{" .. identifier .. "}"
    ),
    figure,
  })
end

return {
  { Table = mark_figures_inside_table },
  { Figure = mark_deferred_figure },
}
