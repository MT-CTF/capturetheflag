local function fix(parent, child)
	if child ~= nil then
		child.p = parent
	end
	local s = 1
	if parent.l then
		s = s + parent.l.s
	end
	if parent.r then
		s = s + parent.r.s
	end
	parent.s = s
end

local function split(tree, key)
	if not tree then
		return nil, nil
	end
	if key > tree.x then
		local tree1, tree2 = split(tree.r, key)
		tree.r = tree1
		fix(tree, tree.r)
		return tree, tree2
	else
		local tree1, tree2 = split(tree.l, key)
		tree.l = tree2
		fix(tree, tree.l)
		return tree1, tree
	end
end

local function merge(tree1, tree2)
	if not tree2 then
		return tree1
	end
	if not tree1 then
		return tree2
	end
	if tree1.y > tree2.y then
		tree1.r = merge(tree1.r, tree2)
		fix(tree1, tree1.r)
		return tree1
	else
		tree2.l = merge(tree1, tree2.l)
		fix(tree2, tree2.l)
		return tree2
	end
end

local function get_top_rec(node, count, ret)
	if not node then
		return
	end

	get_top_rec(node.r, count, ret)
	if #ret < count then
		table.insert(ret, node.n)
	end
	if #ret < count then
		get_top_rec(node.l, count, ret)
	end
end

local function insert(self, node)
	local tmp_node = self.root
	local parent = nil
	local dir = nil

	while tmp_node and tmp_node.y > node.y do
		tmp_node.s = tmp_node.s + 1
		parent = tmp_node
		if tmp_node.x > node.x then
			dir = false
			tmp_node = tmp_node.l
		else
			dir = true
			tmp_node = tmp_node.r
		end
	end
	node.l, node.r = split(tmp_node, node.x)
	if node.l then
		node.l.p = node
	end
	fix(node, node.r)
	node.p = parent

	if not parent then
		self.root = node
	else
		if dir then
			parent.r = node
		else
			parent.l = node
		end
	end
end

local function add(self, player, score)
	local new = {x=score, y=math.random(), s=1, n=player}
	self.players[player] = new

	if not self.root then
		self.root = new
		return
	end

	insert(self, new)
end

local function remove(self, node)
	local tmp_node = node
	while tmp_node do
		tmp_node.s = tmp_node.s - 1
		tmp_node = tmp_node.p
	end

	local new = merge(node.l, node.r)
	if new then
		new.p = node.p
	end

	if not node.p then
		self.root = new
	else
		if node.p.l == node then
			node.p.l = new
		else
			node.p.r = new
		end
	end
end

local top = {}

function top:new()
	local o = {
		players = {},
		root = nil,
	}
	setmetatable(o, {__index=self})
	return o
end

function top:set(player, score)
	if score == 0 then
		local node = self.players[player]
		if node then
			remove(self, node)
			self.players[player] = nil
		end
		return
	end

	local node = self.players[player]
	if not node then
		add(self, player, score)
		return
	end

	local need_move = false
	if score > node.x then
		local next_node = node.r
		if not next_node then
			local tmp_node = node
			while tmp_node do
				if tmp_node.p and tmp_node.p.l == tmp_node then
					next_node = tmp_node.p
					break
				end
				tmp_node = tmp_node.p
			end
		end
		if next_node and next_node.x < score then
			need_move = true
		end
	elseif score < node.x then
		local next_node = node.l
		if not next_node then
			local tmp_node = node
			while tmp_node do
				if tmp_node.p and tmp_node.p.r == tmp_node then
					next_node = tmp_node.p
					break
				end
				tmp_node = tmp_node.p
			end
		end
		if next_node and next_node.x > score then
			need_move = true
		end
	end

	if not need_move then
		node.x = score
		return
	end

	remove(self, node)
	node.x = score
	insert(self, node)
end

function top:get_place(player)
	local node = self.players[player]
	if not node then
		if self.root then
			return self.root.s + 1
		end
		return 1
	end

	local s = 1
	if node and node.r then
		s = s + node.r.s
	end

	while node do
		if node.p and node.p.r ~= node then
			s = s + 1
			if node.p.r then
				s = s + node.p.r.s
			end
		end
		node = node.p
	end
	return s
end

function top:get_top(count)
	local ret = {}
	if count > 0 then
		get_top_rec(self.root, count, ret)
	end
	return ret
end

return top
