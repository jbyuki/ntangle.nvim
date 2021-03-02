@desc+=
"This is actually the implementation of a double linked list"

@*=
linkedlist = {}
@functions

@functions+=
function linkedlist.push_back(list, el)
	@create_new_element
	if list.tail  then
		@add_element_to_tail
	else
		@add_first_element
	end
	@return_new_element
end

@create_new_element+=
local node = { data = el }

@add_element_to_tail+=
list.tail.next = node
node.prev = list.tail
list.tail = node

@add_first_element+=
list.tail  = node
list.head  = node

@functions+=
function linkedlist.push_front(list, el)
	@create_new_element
	if list.head then
		@add_element_to_head
	else
		@add_first_element
	end
	@return_new_element
end

@add_element_to_head+=
node.next = list.head
list.head.prev = node
list.head = node

@return_new_element+=
return node

@o+=
local a

@functions+=
function linkedlist.insert_after(list, it, el)
	@create_new_element
	if it.next == nil then
		@insert_el_in_tail
	else
		@insert_el_in_between
	end
	@return_new_element
end

@insert_el_in_tail+=
it.next = node
node.prev = it
list.tail = it

@insert_el_in_between+=
node.next = it.next
node.prev = it
node.next.prev = node
it.next = node

@functions+=
function linkedlist.remove(list, it)
	if list.head == it then
		@remove_at_head
	elseif list.tail == it then
		@remove_at_tail
	else
		@remove_in_between
	end
end

@remove_at_head+=
if it.next then
	it.next.prev = nil
else
	list.tail = nil
end
list.head = list.head.next

@remove_at_tail+=
if it.prev then
	it.prev.next = nil
else
	list.head = nil
end
list.tail = list.tail.prev

@remove_in_between+=
it.prev.next = it.next
it.next.prev = it.prev

@functions+=
function linkedlist.get_size(list)
	local l = list.head
	local s = 0
	while l do
		l = l.next
		s = s + 1
	end
	return s
end

@functions+=
function linkedlist.iter_from(pos)
	return function ()
		local cur = pos
		if cur then 
			pos = pos.next
			return cur 
		end
	end
end

@functions+=
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

@functions+=
function linkedlist.iter_from_back(pos)
	return function ()
		local cur = pos
		if cur then 
			pos = pos.prev
			return cur 
		end
	end
end
