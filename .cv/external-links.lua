function Link(el)
  if el.target:match("^https?://") then
    el.attr.attributes["target"] = "_blank"
    el.attr.attributes["rel"] = "noopener noreferrer"
  end
  return el
end
