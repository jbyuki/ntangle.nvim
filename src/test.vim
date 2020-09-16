lua << END
function test()
	print("hello")
end
END

call v:lua.test()
