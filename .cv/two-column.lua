-- PDF-only layout: split the flat document into a full-width header band
-- plus two columns. Blocks before "## Work" become .cv-header (name, title,
-- rule); "## Work" up to "## Community" becomes .cv-main (wide, left);
-- Community onward becomes .cv-sidebar (narrow, right). Used only for the
-- PDF pass, not index.html.

function Pandoc(doc)
  local header = {}
  local main = {}
  local sidebar = {}
  local target = header

  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 2 then
      if block.attr.identifier == "work" then
        target = main
      elseif block.attr.identifier == "community" then
        target = sidebar
      end
    end
    table.insert(target, block)
  end

  return pandoc.Pandoc({
    pandoc.Div(header, pandoc.Attr("", {"cv-header"})),
    pandoc.Div(main, pandoc.Attr("", {"cv-main"})),
    pandoc.Div(sidebar, pandoc.Attr("", {"cv-sidebar"}))
  }, doc.meta)
end
