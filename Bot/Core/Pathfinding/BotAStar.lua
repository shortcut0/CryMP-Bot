-------------------------------------------------------------------------
-- Sources obtained from https://github.com/lattejed/a-star-lua
-- Minor changes made by shortcut0

-- ======================================================================
-- Copyright (c) 2012 RapidFire Studio Limited 
-- All Rights Reserved. 
-- http://www.rapidfirestudio.com

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ======================================================================

----------------------------------------------------------------
-- local variables
----------------------------------------------------------------

local INF = 1/0
local cachedPaths = nil

----------------------------------------------------------------
-- local functions
----------------------------------------------------------------

--------------------------------
-- dist
function dist ( x1, y1, x2, y2 )
	return math.sqrt ( math.pow ( x2 - x1, 2 ) + math.pow ( y2 - y1, 2 ) )
end

--------------------------------
-- dist
function dist_between ( nodeA, nodeB )
	return dist ( nodeA.x, nodeA.y, nodeB.x, nodeB.y )
end

--------------------------------
-- heuristic_cost_estimate
function heuristic_cost_estimate ( nodeA, nodeB )
	return dist ( nodeA.x, nodeA.y, nodeB.x, nodeB.y )
end

--------------------------------
-- is_valid_node
function is_valid_node (node, neighbor)
	return true
end

--------------------------------
-- lowest_f_score
function lowest_f_score (set, f_score)

	local lowest, bestNode = INF, nil
	for _, node in ipairs ( set ) do
		local score = f_score [ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end

--------------------------------
-- neighbor_nodes
function neighbor_nodes (theNode, nodes)
	local aNeighbors = {}
	for _, node in ipairs(nodes) do
		if (theNode ~= node and is_valid_node(theNode, node)) then
			table.insert (aNeighbors, node) end
	end
	return aNeighbors
end

--------------------------------
-- not_in
function not_in (set, theNode)
	for _, node in ipairs( set ) do
		if (node == theNode) then 
			return false end
	end
	return true
end

--------------------------------
-- remove_node
function remove_node (set, theNode)

	for i, node in ipairs(set) do
		if (node == theNode) then 
			set [ i ] = set [ #set ]
			set [ #set ] = nil
			break
		end
	end	
end

--------------------------------
-- unwind_path
function unwind_path (flat_path, map, current_node)
	if (map[current_node]) then
		table.insert(flat_path, 1, map [ current_node ]) 
		return unwind_path(flat_path, map, map [ current_node ])
	else
		return flat_path
	end
end

----------------------------------------------------------------
-- pathfinding functions
----------------------------------------------------------------

function a_star ( start, goal, nodes, valid_node_func )

	----------------------
	local aClosedSet = {}
	local aOpenSet = { start }
	local aCameFrom = {}

	----------------------
	if (valid_node_func) then 
		is_valid_node = valid_node_func end

	----------------------
	local g_score, f_score = {}, {}
	g_score [ start ] = 0
	f_score [ start ] = g_score [ start ] + heuristic_cost_estimate ( start, goal )

	----------------------
	while (#aOpenSet > 0) do
	
		----------------------
		local current = lowest_f_score(aOpenSet, f_score)
		if (current == goal) then
			local path = unwind_path ({}, aCameFrom, goal)
			table.insert(path, goal)
			return path
		end

		----------------------
		remove_node ( aOpenSet, current )		
		table.insert ( aClosedSet, current )
		
		----------------------
		local neighbors = neighbor_nodes ( current, nodes )
		for _, neighbor in ipairs ( neighbors ) do 
			if (not_in (aClosedSet, neighbor)) then
			
				----------------------
				local tentative_g_score = g_score [ current ] + dist_between ( current, neighbor )
				
				----------------------
				if (not_in(aOpenSet, neighbor) or tentative_g_score < g_score [neighbor]) then 
					aCameFrom 	[neighbor] = current
					g_score 	[neighbor] = tentative_g_score
					f_score 	[neighbor] = g_score [ neighbor ] + heuristic_cost_estimate ( neighbor, goal )
					
					----------------------
					if (not_in (aOpenSet, neighbor)) then
						table.insert(aOpenSet, neighbor)
					end
				end
			end
		end
	end
	
	----------------------
	return nil -- no valid path
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

--------------------------------
-- clear_cached_paths
function clear_cached_paths()
	cachedPaths = nil
end

--------------------------------
-- distance
function distance(x1, y1, x2, y2)
	return dist(x1, y1, x2, y2)
end

--------------------------------
-- path
function path(start, goal, nodes, ignore_cache, valid_node_func)

	----------------------
	if (not cachedPaths) then 
		cachedPaths = {} end
		
	----------------------
	if (not cachedPaths[start]) then
		cachedPaths[start] = {}
	elseif (cachedPaths[start][goal] and not ignore_cache) then
		return cachedPaths[start][goal]
	end

	----------------------
	local aResPath = a_star ( start, goal, nodes, valid_node_func )
	if (not cachedPaths[start][goal] and not ignore_cache) then
		cachedPaths[start][goal] = aResPath
	end

	----------------------
	return aResPath
end

--------------------------------
astar = {
	path = path,
	distance = distance,
	clear_cached_paths = clear_cached_paths
}

--------------------------------
return astar