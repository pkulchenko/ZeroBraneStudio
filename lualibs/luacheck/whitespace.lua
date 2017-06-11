local function check_whitespace(chstate, lines, line_endings)
   for line_number, line in ipairs(lines) do
      if line ~= "" then
         local from, to = line:find("%s+$")

         if from then
            local code

            if from == 1 then
               -- Line contains only whitespace (thus never considered "code").
               code = "611"
            elseif not line_endings[line_number] then
               -- Trailing whitespace on code line or after long comment.
               code = "612"
            elseif line_endings[line_number] == "string" then
               -- Trailing whitespace embedded in a string literal.
               code = "613"
            elseif line_endings[line_number] == "comment" then
            -- Trailing whitespace at the end of a line comment or inside long comment.
               code = "614"
            end

            chstate:warn({code = code, line = line_number, column = from, end_column = to})
         end

         from, to = line:find("^%s+")

         if from and to ~= #line and line:sub(1, to):find(" \t") then
            -- Inconsistent leading whitespace (SPACE followed by TAB).
            chstate:warn({code = "621", line = line_number, column = from, end_column = to})
         end
      end
   end
end

return check_whitespace
