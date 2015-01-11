
SEARCH_STATE_NOT_INITIALISED = 0
SEARCH_STATE_SEARCHING = 1
SEARCH_STATE_SUCCEEDED = 2
SEARCH_STATE_FAILED = 3
SEARCH_STATE_OUT_OF_MEMORY = 4
SEARCH_STATE_INVALID = 5

-- 对array[first..last]进行堆筛选
function sift_heap(array, first, last)
    local i = first             -- 被筛选结点索引
    local j = 2 * i             -- 被筛选结点的左孩子索引
    local temp = array[i]       -- 保存被筛选结点
    
    while (j <= last) do
        if (j < last and array[j].f > array[j + 1].f) then
            j = j + 1           -- 若右孩子较小，把j指向右孩子
        end
        
        if (temp.f > array[j].f) then
            array[i] = array[j] -- 将array[j]调整到双亲结点位置上
            i = j               -- 修改i和j值，指向下一个被筛选结点和被筛选结点的左孩子
            j = 2 * i
        else
            break               -- 已是小根堆，筛选结束
        end
    end
    
    array[i] = temp             -- 被筛选结点的值放入最终位置
end

-- 建立初始小根堆
function make_heap(array, first, last)
    local n = last - first + 1
    for i = math.floor(n/2), 1, -1 do
        sift_heap(array, i, n)
    end
end

-- 往小根堆中插入一个结点
function push_heap(array, first, last)
    make_heap(array, first, last)
end

-- 从小根堆中弹出一个结点
function pop_heap(array, first, last)
    array[first], array[last] = array[last], array[first]  
    make_heap(array, first, last-1)
end

-- 打印数组
function print_heap(array)
    str = ""
    for i = 1, #array do
        str = str .. array[i] .. "," 
    end
    print("#######################", str)
end

-- The AStar search class.
local AStarSearch = class("AStarSearch")
local Node = class("Node")

function Node:ctor()
    self.parent = nil   -- used during the search to record the parent of successor nodes
    self.child = nil    -- used after the search for the application to view the search in reverse
    self.g = 0.0        -- cost of this node + it's predecessors
    self.h = 0.0        -- heuristic estimate of distance to goal
    self.f = 0.0        -- sum of cumulative cost of predecessors and self and heuristic
    self.m_UserState = nil
end

-- constructor just initialises private data
function AStarSearch:ctor(nMaxNodes)
    self.m_AllocateNodeCount = 0
    self.m_State = SEARCH_STATE_NOT_INITIALISED
    self.m_CurrentSolutionNode = nil
    self.m_CancelRequest = false
        
    -- Heap (simple vector but used as a heap, cf. Steve Rabin's game gems article)
    self.m_OpenList = {}

    -- Closed list is a vector.
    self.m_ClosedList = {} 

    -- Successors is a vector filled out by the user each type successors to a node
    -- are generated
    self.m_Successors = {}

    -- State
    self.m_State = 0

    -- Counts steps
    self.m_Steps = 0

    -- Start and goal state pointers
    self.m_Start = nil
    self.m_Goal = nil

    self.m_CurrentSolutionNode = nil
    
    -- Debug : need to keep these two iterators around
    -- for the user Dbg functions
    self.iterDbgOpen = 1
    self.iterDbgClosed = 1
    
    self.m_CancelRequest = false
end

-- call at any time to cancel the search and free up all the memory
function AStarSearch:cancelSearch()
    self.m_CancelRequest = true
end

-- Set Start and goal states
function AStarSearch:setStartAndGoalStates(Start, Goal)
    self.m_CancelRequest = false

    self.m_Start = Node.new()
    self.m_Goal = Node.new()
        
    self.m_Start.m_UserState = Start
    self.m_Goal.m_UserState = Goal

    self.m_State = SEARCH_STATE_SEARCHING
        
    -- Initialise the AStar specific parts of the Start Node
    -- The user only needs fill out the state information

    self.m_Start.g = 0 
    self.m_Start.h = self.m_Start.m_UserState:goalDistanceEstimate(self.m_Goal.m_UserState)
    self.m_Start.f = self.m_Start.g + self.m_Start.h
    self.m_Start.parent = nil

    -- Push the start node on the Open list
    
    table.insert(self.m_OpenList, self.m_Start) -- heap now unsorted

    -- Sort back element into heap
    push_heap(self.m_OpenList, 1, #self.m_OpenList)

    -- Initialise counter for search steps
    self.m_Steps = 0
end

-- Advances search one step 
function AStarSearch:searchStep()
    -- Firstly break if the user has not initialised the search
    if (not ((self.m_State > SEARCH_STATE_NOT_INITIALISED) and 
        (self.m_State < SEARCH_STATE_INVALID))) then
        return self.m_State
    end

    -- Next I want it to be safe to do a searchstep once the search has succeeded...
    if ((self.m_State == SEARCH_STATE_SUCCEEDED) or
        (self.m_State == SEARCH_STATE_FAILED)) then
        return self.m_State
    end

    -- Failure is defined as emptying the open list as there is nothing left to 
    -- search...
    -- New: Allow user abort
    if (#self.m_OpenList <= 0 or self.m_CancelRequest) then
        self:freeAllNodes()
        self.m_State = SEARCH_STATE_FAILED
        return self.m_State
    end
        
    -- Incremement step count
    self.m_Steps = self.m_Steps + 1

    -- Pop the best node (the one with the lowest f) 
    local n = self.m_OpenList[1]    -- get pointer to the node
    pop_heap(self.m_OpenList, 1, #self.m_OpenList)
    table.remove(self.m_OpenList)

    -- Check for the goal, once we pop that we're done
    if (n.m_UserState:isGoal(self.m_Goal.m_UserState)) then
        -- The user is going to use the Goal Node he passed in 
        -- so copy the parent pointer of n 
        self.m_Goal.parent = n.parent

        -- A special case is that the goal was passed in as the start state
        -- so handle that here
        if (false == n.m_UserState:isSameState(self.m_Start.m_UserState)) then
            n = nil

            -- set the child pointers in each node (except Goal which has no child)
            local nodeChild = self.m_Goal
            local nodeParent = self.m_Goal.parent

            repeat
                nodeParent.child = nodeChild
                nodeChild = nodeParent
                nodeParent = nodeParent.parent
            until (not (nodeChild ~= self.m_Start))  -- Start is always the first node by definition
        end

        -- delete nodes that aren't needed for the solution
        self:freeUnusedNodes()
        self.m_State = SEARCH_STATE_SUCCEEDED
        return self.m_State
    else    -- not goal

        -- We now need to generate the successors of this node
        -- The user helps us to do this, and we keep the new nodes in
        -- m_Successors ...

        self.m_Successors = {}  -- empty vector of successor nodes to n

        -- User provides this functions and uses AddSuccessor to add each successor of
        -- node 'n' to m_Successors
        local ret = n.m_UserState:getSuccessors(self, (n.parent and n.parent.m_UserState) or nil) 

        if (not ret) then
            -- free the nodes that may previously have been added 
--            for i = 1, #self.m_Successors do
--                self.m_Successors[i] = nil
--            end

            self.m_Successors = {}  -- empty vector of successor nodes to n

            -- free up everything else we allocated
            self:freeAllNodes()

            self.m_State = SEARCH_STATE_OUT_OF_MEMORY
            return self.m_State
        end

        local successor = nil
        
        -- Now handle each successor to the current node ...
        for i = 1, #self.m_Successors do
            successor = self.m_Successors[i]
            
            -- The g value for this successor ...
            local newg = n.g + n.m_UserState:getCost(successor.m_UserState)

            -- Now we need to find whether the node is on the open or closed lists
            -- If it is but the node that is already on them is better (lower g)
            -- then we can forget about this successor

            -- First linear search of open list to find node

            local openlist_result = nil
            local openlist_index = 1
            for j = 1, #self.m_OpenList do
                if (self.m_OpenList[j].m_UserState:isSameState(successor.m_UserState)) then
                    openlist_result = self.m_OpenList[j]
                    openlist_index = j
                    break
                end
            end

            if (openlist_result and openlist_result.g <= newg) then
                -- we found this state on open

                successor = nil

                -- the one on Open is cheaper than this one
                -- continue
            else
                local closedlist_result = nil
                local closedlist_index = 1
                for j = 1, #self.m_ClosedList do
                    if (self.m_ClosedList[j].m_UserState:isSameState(successor.m_UserState)) then
                        closedlist_result = self.m_ClosedList[j]
                        closedlist_index = j
                        break
                    end
                end

                if (closedlist_result and closedlist_result.g <= newg) then
                    -- we found this state on closed

                    -- the one on Closed is cheaper than this one
                    successor = nil
                    -- continue
                else
                    -- This node is the best node so far with this particular state
                    -- so lets keep it and set up its AStar specific data ...

                    successor.parent = n
                    successor.g = newg
                    successor.h = successor.m_UserState:goalDistanceEstimate(self.m_Goal.m_UserState)
                    successor.f = successor.g + successor.h

                    -- Remove successor from closed if it was on it

                    if (closedlist_result) then
                        -- remove it from Closed
                        table.remove(self.m_ClosedList, closedlist_index)
                        closedlist_result = nil 

                        -- Fix thanks to ...
                        -- Greg Douglas <gregdouglasmail@gmail.com>
                        -- who noticed that this code path was incorrect
                        -- Here we have found a new state which is already CLOSED
                        -- anus
                    end

                    -- Update old version of this node
                    if (openlist_result) then
                        table.remove(self.m_OpenList, openlist_index)
                        openlist_result = nil 

                        -- re-make the heap 
                        -- make_heap rather than sort_heap is an essential bug fix
                        -- thanks to Mike Ryynanen for pointing this out and then explaining
                        -- it in detail. sort_heap called on an invalid heap does not work
                        make_heap(self.m_OpenList, 1, #self.m_OpenList)
                    end

                    -- heap now unsorted
                    table.insert(self.m_OpenList, successor)

                    -- sort back element into heap
                    push_heap(self.m_OpenList, 1, #self.m_OpenList) 
                end
            end
        end

        -- push n onto Closed, as we have expanded it now

        table.insert(self.m_ClosedList, n)
    end -- end else (not goal so expand)
    
    return self.m_State -- Succeeded bool is false at this point. 
end

-- User calls this to add a successor to a list of successors
-- when expanding the search frontier
function AStarSearch:addSuccessor(state)
    local node = Node.new()

    if (node) then
        node.m_UserState = state
        table.insert(self.m_Successors, node)
        return true
    end

    return false
end

-- Free the solution nodes
-- This is done to clean up all used Node memory when you are done with the
-- search
function AStarSearch:freeSolutionNodes()
    local n = self.m_Start

    if (self.m_Start.child) then
        repeat
            local del = n
            n = n.child
            del = nil
        until (not (n ~= self.m_Goal))

        n = nil -- Delete the goal
    else
        -- if the start node is the solution we need to just delete the start and goal
        -- nodes
        self.m_Start = nil
        self.m_Goal = nil
    end
end

-- Functions for traversing the solution

-- Get start node
function AStarSearch:getSolutionStart()
    self.m_CurrentSolutionNode = self.m_Start
    if (self.m_Start) then
        return self.m_Start.m_UserState
    else
        return nil
    end
end
    
-- Get next node
function AStarSearch:getSolutionNext()
    if (self.m_CurrentSolutionNode) then
        if (self.m_CurrentSolutionNode.child) then
            local child = self.m_CurrentSolutionNode.child

            self.m_CurrentSolutionNode = self.m_CurrentSolutionNode.child

            return child.m_UserState
        end
    end

    return nil
end
    
-- Get end node
function AStarSearch:getSolutionEnd()
    self.m_CurrentSolutionNode = self.m_Goal
    if (self.m_Goal) then
        return self.m_Goal.m_UserState
    else
        return nil
    end
end
    
-- Step solution iterator backwards
function AStarSearch:getSolutionPrev()
    if (self.m_CurrentSolutionNode) then
        if (self.m_CurrentSolutionNode.parent) then
            local parent = self.m_CurrentSolutionNode.parent
            self.m_CurrentSolutionNode = self.m_CurrentSolutionNode.parent
            return parent.m_UserState
        end
    end

    return nil
end

-- For educational use and debugging it is useful to be able to view
-- the open and closed list at each step, here are two functions to allow that.
function AStarSearch:getOpenListStart()
    self.iterDbgOpen = 1
    local iter = self.m_OpenList[self.iterDbgOpen]
    if (not iter) then
        return iter.f, iter.g, iter.h, iter.m_UserState
    end

    return nil
end

function AStarSearch:getOpenListNext()
    self.iterDbgOpen = self.iterDbgOpen + 1
    local iter = self.m_OpenList[self.iterDbgOpen]
    if (not iter) then
        return iter.f, iter.g, iter.h, iter.m_UserState
    end

    return nil
end

function AStarSearch:getClosedListStart()
    self.iterDbgClosed = 1
    local iter = self.m_ClosedList[self.iterDbgClosed]
    if (not iter) then
        return iter.f, iter.g, iter.h, iter.m_UserState
    end

    return nil
end

function AStarSearch:getClosedListNext()
    self.iterDbgClosed = self.iterDbgClosed + 1
    local iter = self.m_ClosedList[self.iterDbgClosed]
    if (not iter) then
        return iter.f, iter.g, iter.h, iter.m_UserState
    end

    return nil
end

-- Get the number of steps
function AStarSearch:getStepCount()
    return self.m_Steps
end

function AStarSearch:ensureMemoryFreed()
    -- assert(m_AllocateNodeCount == 0);
end

-- This is called when a search fails or is cancelled to free all used
-- memory 
function AStarSearch:freeAllNodes()
    self.m_OpenList = {}
    self.m_ClosedList = {}
end


-- This call is made by the search class when the search ends. A lot of nodes may be
-- created that are still present when the search ends. They will be deleted by this 
-- routine once the search ends
function AStarSearch:freeUnusedNodes()
    self.m_OpenList = {}
    self.m_ClosedList = {}
end

return AStarSearch