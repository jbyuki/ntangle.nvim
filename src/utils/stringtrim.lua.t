##../ntangle_main
@declare_functions+=
local trim1

@functions+=
-- http://lua-users.org/wiki/StringTrim
function trim1(s)
   return s:gsub("^%s*(.-)%s*$", "%1")
end
