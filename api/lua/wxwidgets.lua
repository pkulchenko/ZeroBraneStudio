local function populateAPI(t)
  local api = {}
  local function processFields(fields)
    for k,v in pairs(fields) do
      if type(v) == "table" then
        api[k] = {
          type = "class",
          description = "",
          returns = "",
          childs = populateAPI(v)
        }
      else
        api[k] = {
          type = (type(v) == "function" and "function" or "value"),
          description = "",
          returns = "",
        }
      end
    end
  end
  processFields(t)

  return api
end

return {
  wx = {
    type = "lib",
    description = "wx lib",
    childs = populateAPI(wx),
  },
  wxstc = {
    type = "lib",
    description = "wxSTC lib",
    childs = populateAPI(wxstc),
  },
  wxaui = {
    type = "lib",
    description = "wxAUI lib",
    childs = populateAPI(wxaui),
  }
}
