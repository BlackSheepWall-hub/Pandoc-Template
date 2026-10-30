-- Put vertical padding into the actual first and last text lines of every
-- table cell.  Pandoc wraps fixed-width header cells in minipages, so changing
-- only array struts does not move the first line of a multi-line header.

if not FORMAT:match("latex") then
  return {}
end

local function first_text_block(blocks)
  for index, block in ipairs(blocks) do
    if block.t == "Plain" or block.t == "Para" then
      return index
    end
  end
end

local function last_text_block(blocks)
  for index = #blocks, 1, -1 do
    local block = blocks[index]
    if block.t == "Plain" or block.t == "Para" then
      return index
    end
  end
end

local function pad_cell(cell)
  local first = first_text_block(cell.contents)
  local last = last_text_block(cell.contents)
  if not first or not last then
    return
  end

  cell.contents[first].content:insert(
    1,
    pandoc.RawInline("latex", "\\HomeworkCellTopStrut{}")
  )
  cell.contents[last].content:insert(
    pandoc.RawInline("latex", "\\HomeworkCellBottomStrut{}")
  )
end

local function pad_rows(rows)
  for _, row in ipairs(rows) do
    for _, cell in ipairs(row.cells) do
      pad_cell(cell)
    end
  end
end

local function pad_table(table_element)
  pad_rows(table_element.head.rows)
  for _, body in ipairs(table_element.bodies) do
    pad_rows(body.head)
    pad_rows(body.body)
  end
  pad_rows(table_element.foot.rows)
  return table_element
end

return { Table = pad_table }
