##ntangle_main
@declare_functions+=
local debug_array

@functions+=
function debug_array(l)
	for i, li in ipairs(l) do
		print(i .. ": " .. vim.inspect(li))
	end
end
