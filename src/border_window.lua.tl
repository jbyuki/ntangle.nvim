##ntangle_main
@fill_buffer_with_border_characters+=
local border_text = {}

local border_chars = {
	topleft  = '╭',
	topright = '╮',
	top      = '─',
	left     = '│',
	right    = '│',
	botleft  = '╰',
	botright = '╯',
	bot      = '─',
}

-- local border_chars = {
	-- topleft  = '╔',
	-- topright = '╗',
	-- top      = '═',
	-- left     = '║',
	-- right    = '║',
	-- botleft  = '╚',
	-- botright = '╝',
	-- bot      = '═',
-- }

for y=1,border_opts.height do
	local line = ""
	if y == 1 then
		if not center_title then
			@create_border_top
		else
			@create_border_top_with_title_center
		end
	elseif y == border_opts.height then
		@create_border_bottom
	else
		@create_border_middle
	end
	table.insert(border_text, line)
end

vim.api.nvim_buf_set_lines(borderbuf, 0, -1, true, border_text)

@create_border_top+=
line = border_chars.topleft .. border_chars.top
local title_len = 0
if border_title then
	line = line .. border_title
	title_len = vim.api.nvim_strwidth(border_title)
end

for x=2+title_len+1,border_opts.width-1 do
	line = line .. border_chars.top
end
line = line .. border_chars.topright

@create_border_top_with_title_center+=
line = border_chars.topleft

local title_len = 0
if border_title then
	title_len = vim.api.nvim_strwidth(border_title)
end

local pad_left = math.floor((border_opts.width-title_len)/2)

for x=2,pad_left do
	line = line .. border_chars.top
end

if border_title then
	line = line .. border_title
end

for x=pad_left+title_len+1,border_opts.width-1 do
	line = line .. border_chars.top
end

line = line .. border_chars.topright

@create_border_bottom+=
line = border_chars.botleft
for x=2,border_opts.width-1 do
	line = line .. border_chars.bot
end
line = line .. border_chars.botright

@create_border_middle+=
line = border_chars.left
for x=2,border_opts.width-1 do
	line = line .. " "
end
line = line .. border_chars.right
