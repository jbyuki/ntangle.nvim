-- Generated from linkedlist.lua.t using ntangle.nvim
linkedlist = {}
function linkedlist.push_back(list, el)
	local node = { data = el }
	
	if list.tail  then
		list.tail.next = node
		node.prev = list.tail
		list.tail = node
		
	else
		list.tail  = node
		list.head  = node
		
	end
	return node
	
end

function linkedlist.push_front(list, el)
	local node = { data = el }
	
	if list.head then
		node.next = list.head
		list.head.prev = node
		list.head = node
		
	else
		list.tail  = node
		list.head  = node
		
	end
	return node
	
end

function linkedlist.insert_after(list, it, el)
	local node = { data = el }
	
	if it.next == nil then
		it.next = node
		node.prev = it
		list.tail = it
		
	else
		node.next = it.next
		node.prev = it
		node.next.prev = node
		it.next = node
		
	end
	return node
	
end

function linkedlist.remove(list, it)
	if list.head == it then
		if it.next then
			it.next.prev = nil
		else
			list.tail = nil
		end
		list.head = list.head.next
		
	elseif list.tail == it then
		if it.prev then
			it.prev.next = nil
		else
			list.head = nil
		end
		list.tail = list.tail.prev
		
	else
		it.prev.next = it.next
		it.next.prev = it.prev
		
	end
end

function linkedlist.get_size(list)
	local l = list.head
	local s = 0
	while l do
		l = l.next
		s = s + 1
	end
	return s
end

function linkedlist.iter_from(pos)
	return function ()
		local cur = pos
		if cur then 
			pos = pos.next
			return cur 
		end
	end
end

function linkedlist.iter(list)
	local pos = list.head
	return function ()
		local cur = pos
		if cur then 
			pos = pos.next
			return cur.data
		end
	end
end

function linkedlist.iter_from_back(pos)
	return function ()
		local cur = pos
		if cur then 
			pos = pos.prev
			return cur 
		end
	end
end

