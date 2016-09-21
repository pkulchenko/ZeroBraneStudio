-- Copyright 2011-14 Paul Kulchenko, ZeroBrane LLC
-- authors: Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

local ide = ide

ide.iofilters["0d0d0aFix"] = {
  -- this function converts 0d0d0a line ending to 0d0a
  input = function(fpath, content)
    return content:gsub("\013\013\010","\013\010")
  end,
}

-- which: "input" or "output"
function GetConfigIOFilter(which)
  local filtername = ide.config.editor.iofilter
  return (filtername and ide.iofilters[filtername] and ide.iofilters[filtername][which])
end
