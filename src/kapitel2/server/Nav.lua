-- Wegfindung im Herrenhaus: ein Netz aus Wegpunkten, das nur durch Türen und über Treppen
-- führt. Sarp und die Familie laufen so nie durch Wände oder Decken.
-- Alles hier rechnet in Plan-Koordinaten (x, y) und Stockwerk ("K", "E", "O"); die Umrechnung
-- in die Welt macht Mansion.route.
local Nav = {}
Nav.__index = Nav

local INSET = 1.6 -- Abstand der Türpunkte zur Wand
local CLEARANCE = 0.5 -- so viel Platz soll neben dem Weg frei sein
local STAIR_COST = 1.4

local function inside(poly, x, y)
	local result = false
	local j = #poly
	for i = 1, #poly do
		local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
		if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
			result = not result
		end
		j = i
	end
	return result
end

-- Bleibt die Strecke ganz im Raum (mit etwas Abstand zu den Wänden)?
local function clear(poly, ax, ay, bx, by, margin)
	margin = margin or CLEARANCE
	local length = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
	local steps = math.max(2, math.ceil(length / 0.6))
	for i = 0, steps do
		local t = i / steps
		local x, y = ax + (bx - ax) * t, ay + (by - ay) * t
		if
			not (
				inside(poly, x, y)
				and inside(poly, x + margin, y)
				and inside(poly, x - margin, y)
				and inside(poly, x, y + margin)
				and inside(poly, x, y - margin)
			)
		then
			return false
		end
	end
	return true
end

local function dist(a, b)
	return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

-- config = { rooms = { E = { {id, poly} … }, … }, doors = { {f, x, y, a, b, sides?} … },
--            stairs = { { {x,y,f}, {x,y,f} } … }, hubs = { {f, x, y} … } }
function Nav.new(config)
	local self = setmetatable({ rooms = config.rooms, nodes = {}, edges = {} }, Nav)
	local function roomById(f, id)
		for _, room in config.rooms[f] or {} do
			if room.id == id then
				return room
			end
		end
		return nil
	end
	local function addNode(f, x, y, room)
		for _, other in self.nodes do
			if other.f == f and math.abs(other.x - x) < 0.05 and math.abs(other.y - y) < 0.05 then
				other.room = other.room or room
				return other
			end
		end
		local node = { x = x, y = y, f = f, room = room, index = #self.nodes + 1 }
		table.insert(self.nodes, node)
		self.edges[node.index] = {}
		return node
	end
	local function link(a, b, factor)
		local d = dist(a, b) * (factor or 1)
		table.insert(self.edges[a.index], { to = b.index, cost = d })
		table.insert(self.edges[b.index], { to = a.index, cost = d })
	end
	-- Türen: je ein Punkt davor und dahinter
	for _, door in config.doors do
		local f, x, y, a, b, sides = door[1], door[2], door[3], door[4], door[5], door[6]
		local na, nb
		if sides then
			na = addNode(f, sides[1][1], sides[1][2], a)
			nb = addNode(f, sides[2][1], sides[2][2], b)
		else
			-- Seite ermitteln: der Punkt, der im jeweiligen Raum liegt
			local roomA, roomB = roomById(f, a), roomById(f, b)
			local function side(room)
				for _, d in { { INSET, 0 }, { -INSET, 0 }, { 0, INSET }, { 0, -INSET } } do
					if inside(room.poly, x + d[1], y + d[2]) and not inside(room.poly, x - d[1], y - d[2]) then
						return { x + d[1], y + d[2] }
					end
				end
				return nil
			end
			local sa, sb = side(roomA), side(roomB)
			assert(sa and sb, "Nav: Tür ohne Seiten " .. f .. " " .. x .. "," .. y)
			na = addNode(f, sa[1], sa[2], a)
			nb = addNode(f, sb[1], sb[2], b)
		end
		link(na, nb)
	end
	for _, stair in config.stairs do
		local lower = addNode(stair[1][3], stair[1][1], stair[1][2], stair[1][4])
		local upper = addNode(stair[2][3], stair[2][1], stair[2][2], stair[2][4])
		-- Treppen sind eine eigene Verbindung (Kosten etwas höher, damit sie nur bei Bedarf genommen werden)
		link(lower, upper, STAIR_COST)
	end
	for _, hub in config.hubs or {} do
		addNode(hub[1], hub[2], hub[3], hub[4])
	end
	-- Räume: alle Punkte, die sich im selben Raum sehen, verbinden
	for i, a in self.nodes do
		for j = i + 1, #self.nodes do
			local b = self.nodes[j]
			if a.f == b.f and a.room == b.room and a.room then
				local room = roomById(a.f, a.room)
				if room and clear(room.poly, a.x, a.y, b.x, b.y) then
					link(a, b)
				end
			end
		end
	end
	return self
end

function Nav:roomAt(f, x, y)
	for _, room in self.rooms[f] or {} do
		if inside(room.poly, x, y) then
			return room
		end
	end
	return nil
end

-- Verbindungen eines freien Punkts zu den Wegpunkten (im selben Raum, mit freier Sicht)
function Nav:attach(point)
	local links = {}
	local room = self:roomAt(point.f, point.x, point.y)
	for _, node in self.nodes do
		if node.f == point.f then
			local ok = false
			if room and node.room == room.id then
				ok = clear(room.poly, point.x, point.y, node.x, node.y, 0.1)
			elseif not room and dist(point, node) < 5 then
				ok = true -- steht in einer Türöffnung o. Ä.
			end
			if ok then
				table.insert(links, { to = node.index, cost = dist(point, node) })
			end
		end
	end
	if #links == 0 then
		-- steht in einer Türöffnung o. Ä.: die nächsten Punkte nehmen
		for _, node in self.nodes do
			if node.f == point.f and dist(point, node) < 6 then
				table.insert(links, { to = node.index, cost = dist(point, node) })
			end
		end
	end
	return links, room
end

-- Weg von `from` nach `to` ({x, y, f}); gibt eine Liste von { x, y, f } zurück (ohne den Start,
-- mit dem Ziel) oder nil, wenn es keinen Weg gibt.
function Nav:route(from, to)
	local fromLinks, fromRoom = self:attach(from)
	local toLinks, toRoom = self:attach(to)
	if from.f == to.f and fromRoom and toRoom and fromRoom.id == toRoom.id and clear(fromRoom.poly, from.x, from.y, to.x, to.y, 0.1) then
		return { to }
	end
	local count = #self.nodes
	local best, previous, done = {}, {}, {}
	for i = 1, count do
		best[i] = math.huge
	end
	for _, link in fromLinks do
		if link.cost < best[link.to] then
			best[link.to] = link.cost
			previous[link.to] = 0
		end
	end
	local toCost = {}
	for _, link in toLinks do
		toCost[link.to] = link.cost
	end
	local finish, finishCost = nil, math.huge
	for _ = 1, count do
		local current, currentCost = nil, math.huge
		for i = 1, count do
			if not done[i] and best[i] < currentCost then
				current, currentCost = i, best[i]
			end
		end
		if not current then
			break
		end
		done[current] = true
		if toCost[current] and currentCost + toCost[current] < finishCost then
			finish, finishCost = current, currentCost + toCost[current]
		end
		for _, edge in self.edges[current] do
			if currentCost + edge.cost < best[edge.to] then
				best[edge.to] = currentCost + edge.cost
				previous[edge.to] = current
			end
		end
	end
	if not finish then
		return nil
	end
	local reversed = { to }
	local at = finish
	while at and at ~= 0 do
		local node = self.nodes[at]
		table.insert(reversed, { x = node.x, y = node.y, f = node.f })
		at = previous[at]
	end
	local result = {}
	for i = #reversed, 1, -1 do
		table.insert(result, reversed[i])
	end
	return result
end

return Nav
