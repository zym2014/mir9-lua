local MapPoint = require("app.map.MapPoint")
local AStarSearch = require("app.map.AStarSearch") 

local MapSearchNode = class("MapSearchNode")
local AStarPoint = class("AStarPoint")
local PathAStar = class("PathAStar")

local _roninAStar = nil
local DISORDER = 1

function MapSearchNode:ctor(x, y)
    if (x and y) then
        self.x = x
        self.y = y
    else
        self.x = 0
        self.y = 0
    end
end

function MapSearchNode:isSameState(node)
    -- same state in a maze search is simply when (x,y) are the same
    if((self.x == node.x) and
        (self.y == node.y)) then
        return true
    else
        return false
    end
end

function MapSearchNode:printNodeInfo()
    -- cout << "Node position : (" << x << ", " << y << ")" << endl;
end

-- Here's the heuristic function that estimates the distance from a Node
-- to the Goal. 
function MapSearchNode:goalDistanceEstimate(node)
    local xd = math.abs(self.x - node.x)
    local yd = math.abs(self.y - node.y)
    return xd + yd
end

function MapSearchNode:isGoal(node)
    if((self.x == node.x) and
        (self.y == node.y)) then
        return true
    end

    return false
end

-- This generates the successors to the given Node. It uses a helper function called
-- AddSuccessor to give the successors to the AStar class. The A* specific initialisation
-- is done for each node internally, so here you just set the state information that
-- is specific to the application
function MapSearchNode:getSuccessors(astarsearch, parent_node)
    local parent_x = -1 
    local parent_y = -1

    if (parent_node) then
        parent_x = parent_node.x
        parent_y = parent_node.y
    end
    
    local NewNode

    -- push each possible move except allowing the search to go backwards

    -- 左
    if ((PathAStar.getMap(self.x-1, self.y) ~= DISORDER) and
        not ((parent_x == self.x-1) and (parent_y == self.y))) then 
        NewNode = MapSearchNode.new(self.x-1, self.y)
        astarsearch:addSuccessor(NewNode)
    end

    -- 左上
    if ((PathAStar.getMap(self.x-1, self.y-1) ~= DISORDER) and
        not ((parent_x == self.x-1) and (parent_y == self.y-1))) then
        NewNode = MapSearchNode.new(self.x-1, self.y-1)
        astarsearch:addSuccessor(NewNode)
    end

    -- 上
    if ((PathAStar.getMap(self.x, self.y-1) ~= DISORDER) and 
        not ((parent_x == self.x) and (parent_y == self.y-1))) then
        NewNode = MapSearchNode.new(self.x, self.y-1)
        astarsearch:addSuccessor(NewNode)
    end

    -- 右上
    if ((PathAStar.getMap(self.x+1, self.y-1) ~= DISORDER) and
        not ((parent_x == self.x+1) and (parent_y == self.y-1))) then
        NewNode = MapSearchNode.new(self.x+1, self.y-1)
        astarsearch:addSuccessor(NewNode)
    end

    -- 右
    if ((PathAStar.getMap(self.x+1, self.y) ~= DISORDER) and 
        not ((parent_x == self.x+1) and (parent_y == self.y))) then
        NewNode = MapSearchNode.new(self.x+1, self.y)
        astarsearch:addSuccessor(NewNode)
    end

    -- 右下
    if ((PathAStar.getMap(self.x+1, self.y+1) ~= DISORDER) and 
        not ((parent_x == self.x+1) and (parent_y == self.y+1))) then
        NewNode = MapSearchNode.new(self.x+1, self.y+1)
        astarsearch:addSuccessor(NewNode)
    end
    
    -- 下
    if ((PathAStar.getMap(self.x, self.y+1) ~= DISORDER) and
        not ((parent_x == self.x) and (parent_y == self.y+1))) then
        NewNode = MapSearchNode.new(self.x, self.y+1)
        astarsearch:addSuccessor(NewNode)
    end

    -- 左下
    if ((PathAStar.getMap(self.x-1, self.y+1) ~= DISORDER) and 
        not ((parent_x == self.x-1) and (parent_y == self.y+1))) then
        NewNode = MapSearchNode.new(self.x-1, self.y+1)
        astarsearch:addSuccessor(NewNode)
    end
    
    return true
end

-- given this node, what does it cost to move to successor. In the case
-- of our map the answer is the map terrain value at this node since that is 
-- conceptually where we're moving
function MapSearchNode:getCost(node)
    return PathAStar.getMap(self.x, self.y)
end

function AStarPoint:ctor(x, y)
    self.x = x
    self.y = y
end

function PathAStar:ctor()
end

function PathAStar.getMap(x, y)
    if (0 > x or x >= _roninAStar.m_nRow or 0 > y or y >= _roninAStar.m_nCol) then
        return 1
    end
    
--    if (_roninAStar.m_nMap[y*_roninAStar.m_nRow+x+1] == 1) then
--        return 1
--    end
    
    if (_roninAStar.m_nMap[y][x] == 1) then
        return 1
    end
    
    if (g_mainScene:getMapPoint(MapPoint.new(x * 65536 + y))) then
        return 1
    end
    
    return 0
end

function PathAStar:setData(nRow, nCol, map, nMaxNodes)
    self.m_nMap = map
    self.m_nRow = nRow
    self.m_nCol = nCol
    self.m_nMaxNodes = nMaxNodes
end

function PathAStar.findPathByAStar(map, nRow, nCol, nMaxNodes, beginMPoint, endMPoint)
    if (not _roninAStar) then
        _roninAStar = PathAStar.new()
    end
    _roninAStar:setData(nRow, nCol, map, nMaxNodes)
    
    local dequeMPoint = {}
    local dequeAStarPt = _roninAStar:findPathByAStarInternal(beginMPoint, endMPoint)

    if (#dequeAStarPt <= 1) then
        return dequeMPoint
    end

    for k, v in ipairs(dequeAStarPt) do
        table.insert(dequeMPoint, MapPoint.new(v.x, v.y))
    end

    return dequeMPoint
end

function PathAStar:findPathByAStarInternal(beginMPoint, endMPoint)
    local dequeAStarPt = {}

    local filterEnd = self:getFilterEndPoint(beginMPoint, endMPoint)
    
    local astarsearch = AStarSearch.new(self.m_nMaxNodes)

    local SearchCount = 0

    local NumSearches = 1

    while (SearchCount < NumSearches) do
        
        -- Create a start state
        local nodeStart = MapSearchNode.new()
        nodeStart.x = beginMPoint.x
        nodeStart.y = beginMPoint.z

        -- Define the goal state
        local nodeEnd = MapSearchNode.new()
        nodeEnd.x = filterEnd.x
        nodeEnd.y = filterEnd.z
        
        -- Set Start and goal states
        
        astarsearch:setStartAndGoalStates(nodeStart, nodeEnd)

        local SearchState
        local SearchSteps = 0

        repeat
            SearchState = astarsearch:searchStep()
            SearchSteps = SearchSteps + 1
        until (not (SearchState == SEARCH_STATE_SEARCHING))
        
        if (SearchState == SEARCH_STATE_SUCCEEDED) then
            local node = astarsearch:getSolutionStart()
                
            local steps = 0

            node:printNodeInfo()

            while (true) do
                table.insert(dequeAStarPt, AStarPoint.new(node.x, node.y))
                node = astarsearch:getSolutionNext()
                    
                if (not node) then
                    break
                end

                node:printNodeInfo()
                steps = steps + 1
            end
            
            -- Once you're done with the solution you can free the nodes up
            astarsearch:freeSolutionNodes()
        elseif(SearchState == SEARCH_STATE_FAILED) then
        
        end

        -- Display the number of loops the search went through

        SearchCount = SearchCount + 1

        astarsearch:ensureMemoryFreed()
    end
    
    return dequeAStarPt
end

function PathAStar:getFilterEndPoint(beginMPoint, endMPoint)
    local relust = endMPoint

    if (PathAStar.getMap(endMPoint.x, endMPoint.z) ~= DISORDER) then
        return relust
    end
        
    local count = beginMPoint:getDistance(endMPoint) + 10
    for i = 1, count do
        local arrMPoint = endMPoint:getMapPointVectorForDistance(i)

        local lenght = 0xffff
        for k, v in ipairs(arrMPoint) do
            local mpoint = v
            if (not (PathAStar.getMap(mpoint.x, mpoint.z) == DISORDER or
                mpoint:getDistance(beginMPoint) >= lenght or
                mpoint:equalsObj(beginMPoint))) then
                relust = mpoint
                lenght = mpoint:getDistance(beginMPoint) 
            end
        end
        
        if (not relust:equalsObj(endMPoint)) then
            break
        end
    end

    return relust
end

return PathAStar