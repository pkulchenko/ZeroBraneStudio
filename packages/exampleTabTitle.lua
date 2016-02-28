local id = ID("tabtitle.titleexample")

local P = {
  name = "Custom tab title plugin",
  description = "Demonstrating new tab title callback",
  author = "Thomas Fischer",
}

P.onEditorUpdateTabText = function(self, doc)
  --- filename only (the default)
  title = doc:GetFileName()

  --- or full path?
  title = doc:GetFilePath()
  
  --- example use case: strip project dir from path
  local projectPath = ide:GetProject()
  if projectPath then
    local projectPathLen = projectPath:len()
    local filePath = doc:GetFilePath()
    local findPos = filePath:find(projectPath)
    if filePath:sub(1, projectPathLen) == projectPath then
      title = filePath:sub(projectPathLen + 1)
    end
  end
  
  -- prefer forward slashes even in windows?
  title = string.gsub(title, "\\", "/")

  doc:SetTabText(title)
end

return P
