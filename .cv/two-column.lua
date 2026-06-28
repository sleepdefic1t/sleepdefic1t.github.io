-- PDF-only layout: split the flat document into two columns at "## Community".
-- Everything before becomes .cv-main (wide, left); Community onward becomes
-- .cv-sidebar (narrow, right). Used only for the PDF pass, not index.html.

function Pandoc(doc)
  local main = {}
  local sidebar = {}
  local in_sidebar = false

  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 2 and block.attr.identifier == "community" then
      in_sidebar = true
    end
    if in_sidebar then
      table.insert(sidebar, block)
    else
      table.insert(main, block)
    end
  end

  return pandoc.Pandoc({
    pandoc.Div(main, pandoc.Attr("", {"cv-main"})),
    pandoc.Div(sidebar, pandoc.Attr("", {"cv-sidebar"}))
  }, doc.meta)
end
