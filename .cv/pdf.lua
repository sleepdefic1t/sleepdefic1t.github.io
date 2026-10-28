local SEPARATORS = { ["-"] = true, ["–"] = true, ["—"] = true, ["|"] = true }

local function trim_separators(inlines)
  local trimmed = pandoc.Inlines(inlines)
  local function is_sep(el)
    return el.t == "Space" or (el.t == "Str" and SEPARATORS[el.text])
  end
  while #trimmed > 0 and is_sep(trimmed[1]) do
    trimmed:remove(1)
  end
  while #trimmed > 0 and is_sep(trimmed[#trimmed]) do
    trimmed:remove()
  end
  return trimmed
end

local function flatten_blocks(blocks)
  local inlines = pandoc.Inlines({})
  for _, block in ipairs(blocks) do
    if #inlines > 0 then
      inlines:insert(pandoc.Space())
    end
    if block.t == "BulletList" then
      for i, item in ipairs(block.content) do
        if i > 1 then
          inlines:insert(pandoc.Str(","))
          inlines:insert(pandoc.Space())
        end
        inlines:extend(flatten_blocks(item))
      end
    elseif block.t == "Plain" or block.t == "Para" then
      inlines:extend(block.content)
    end
  end
  return inlines
end

local function find_profile_link(blocks, domain)
  local section = ""
  for _, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 2 then
      section = block.attr.identifier
    elseif section == "links" and block.t == "BulletList" then
      for _, item in ipairs(block.content) do
        local inlines = flatten_blocks(item)
        for _, el in ipairs(inlines) do
          if el.t == "Link" and el.target:find(domain, 1, true) then
            return inlines
          end
        end
      end
    end
  end
end

local function contact_row(kind, inlines)
  return pandoc.Div({ pandoc.Plain(inlines) }, pandoc.Attr("", { "contact", "contact-" .. kind }))
end

local function format_skills(inlines)
  local out = pandoc.Inlines({})
  local skill = pandoc.Inlines({})
  for _, el in ipairs(inlines) do
    if el.t == "Str" and el.text:sub(-1) == "," then
      skill:insert(pandoc.Str(el.text:sub(1, -2)))
      out:insert(pandoc.Span(skill, pandoc.Attr("", { "skill" })))
      out:insert(pandoc.Str("\u{2002}"))
      skill = pandoc.Inlines({})
    elseif el.t ~= "Space" or #skill > 0 then
      skill:insert(el)
    end
  end
  if #skill > 0 then
    out:insert(pandoc.Span(skill, pandoc.Attr("", { "skill" })))
  end
  return pandoc.Para(out)
end

local function compact_volunteer(list)
  local items = {}
  for _, item in ipairs(list.content) do
    if #item > 1 then
      local inlines = flatten_blocks({ item[1] })
      inlines:extend({ pandoc.Space(), pandoc.Str("-"), pandoc.Space() })
      local rest = {}
      for j = 2, #item do
        table.insert(rest, item[j])
      end
      inlines:extend(flatten_blocks(rest))
      table.insert(items, { pandoc.Plain(inlines) })
    elseif #item == 1 then
      table.insert(items, item)
    end
  end
  return pandoc.BulletList(items)
end

function Pandoc(doc)
  local github = find_profile_link(doc.blocks, "github.com/")
  local linkedin = find_profile_link(doc.blocks, "linkedin.com/")

  local name, email, role, location
  local i = 1
  while i <= #doc.blocks do
    local block = doc.blocks[i]
    if block.t == "HorizontalRule" then
      i = i + 1
      break
    end
    if block.t == "Header" and block.level == 2 then
      break
    end
    if block.t == "Header" and block.level == 1 then
      name = block
    elseif block.t == "Para" and #block.content > 0 then
      if block.content[1].t == "Link" and block.content[1].target:match("^mailto:") then
        email = block.content
      elseif block.content[1].t == "Strong" then
        role = block.content[1].content
        local rest = pandoc.Inlines({})
        for j = 2, #block.content do
          rest:insert(block.content[j])
        end
        location = trim_separators(rest)
      end
    end
    i = i + 1
  end

  local identity_blocks = {}
  if name then table.insert(identity_blocks, name) end
  if role then table.insert(identity_blocks, pandoc.Para(role)) end

  local contacts = {}
  if location and #location > 0 then table.insert(contacts, contact_row("location", location)) end
  if email then table.insert(contacts, contact_row("email", email)) end
  if github then table.insert(contacts, contact_row("github", github)) end
  if linkedin then table.insert(contacts, contact_row("linkedin", linkedin)) end

  local output = pandoc.Blocks({
    pandoc.Div({
      pandoc.Div(identity_blocks, pandoc.Attr("", { "identity" })),
      pandoc.Div(contacts, pandoc.Attr("", { "contacts" })),
    }, pandoc.Attr("", { "cv-header" })),
  })

  if i <= #doc.blocks and not (doc.blocks[i].t == "Header" and doc.blocks[i].level == 2) then
    output:insert(pandoc.Header(2, "Summary", pandoc.Attr("summary")))
    while i <= #doc.blocks and not (doc.blocks[i].t == "Header" and doc.blocks[i].level == 2) do
      output:insert(doc.blocks[i])
      i = i + 1
    end
  end

  local section = ""
  while i <= #doc.blocks do
    local block = doc.blocks[i]
    if block.t == "Header" and block.level == 2 then
      section = block.attr.identifier
    end

    if section == "links" then
      i = i + 1
    elseif section == "skills" and block.t == "Para" then
      output:insert(format_skills(block.content))
      i = i + 1
    elseif section == "experience" and block.t == "Header" and block.level == 3 then
      local meta = doc.blocks[i + 1]
      if meta and meta.t == "Para" and #meta.content > 0 and meta.content[#meta.content].t == "Emph" then
        local title_inlines = pandoc.Inlines({})
        for j = 1, #meta.content - 1 do
          title_inlines:insert(meta.content[j])
        end
        local heading_inlines = trim_separators(title_inlines)
        local company_inlines = pandoc.Inlines({ pandoc.Str(","), pandoc.Space() })
        company_inlines:extend(block.content)
        heading_inlines:insert(pandoc.Span(company_inlines, pandoc.Attr("", { "company" })))
        output:insert(pandoc.Div({
          pandoc.Header(3, heading_inlines, block.attr),
          pandoc.Div({ pandoc.Plain(meta.content[#meta.content].content) }, pandoc.Attr("", { "dates" })),
        }, pandoc.Attr("", { "job-header" })))
        i = i + 2
      else
        output:insert(block)
        i = i + 1
      end
    elseif section == "volunteer" and block.t == "BulletList" then
      output:insert(compact_volunteer(block))
      i = i + 1
    else
      output:insert(block)
      i = i + 1
    end
  end

  doc.blocks = output
  return doc
end
