local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

-- Action's possible status
local RUNNING = "RUNNING"
local TERMINATED = "TERMINATED"
local UNINITIALIZED = "UNINITIALIZED"

-- Tree element's possible types
local BRANCH_TYPE = "BRANCH_TYPE"
local LEAF_TYPE = "LEAF_TYPE"

function BehaviorTree.newTree()
    
    local self = setmetatable({}, BehaviorTree)

    self.branch = nil
    self.currentAction = nil

    self.setBranch = BehaviorTree.setBranch
    self.update = BehaviorTree.update

    return self
end

function BehaviorTree:setBranch(branch)
    self.branch = branch
end

function BehaviorTree:update(dt)
    --Skip execution if the tree hasn't been setup yet.
    if (self.branch == nil) then
        return
    end
    --Search the tree for an Action to run if not currently
    --executing an Action.
    if (self.currentAction == nil) then
        self.currentAction = self.branch:evaluate()
        self.currentAction:initialize()
    end
    local status = self.currentAction:update(dt)
    --Clean up the Action once it has terminated.
    if (status == TERMINATED) then
        self.currentAction:cleanUp()
        self.currentAction = nil
    end

end

function BehaviorTree.createAction(name, initializeFunction, updateFunction, cleanUpFunction, user)

    local action = {}

    --action.__index = action

    --The Action's data members.
    action.cleanUpFunction = cleanUpFunction
    action.initializeFunction = initializeFunction
    action.updateFunction = updateFunction

    action.user = user

    action.name = name or ""
    action.status = UNINITIALIZED

    action.type = LEAF_TYPE

    local function initialize(self)
        --Run the initialize function if one is specified.
        if (self.status == UNINITIALIZED) then
            if (self.initializeFunction) then
                self.initializeFunction(self.user)
            end
        end
        --Set the action to running after initializing.
        self.status = RUNNING
    end

    local function update(self, dt)
        if (self.status == TERMINATED) then
            --Immediately return if the Action has already
            --terminated.
            return TERMINATED
        elseif (self.status == RUNNING) then
            if (self.updateFunction) then
                --Run the update function if one is specified.
                self.status = self.updateFunction(self.user,dt)
                --Ensure that a status was returned by the update
                --function.
                assert(self.status)
            else
                --If no update function is present move the action
                --into a terminated state.
                self.status = TERMINATED
            end
        end
        return self.status
    end

    local function cleanUp(self)
        if (self.status == TERMINATED) then
            if (self.cleanUpFunction) then
                self.cleanUpFunction(self.user)
            end
        end
        self.status = UNINITIALIZED
    end

    action.cleanUp = cleanUp
    action.initialize = initialize
    action.update = update

    return action
end

function BehaviorTree.createEvaluator(name, evalFunction, user)

    local evaluator = {}

    --data members
    evaluator.eval_function = evalFunction
    evaluator.name = name or ""
    --object functions

    evaluator.user = user

    local function evaluate(self)
        return self.eval_function(self.user)
    end

    evaluator.evaluate = evaluate

    return evaluator
end

function BehaviorTree.createBranch(name)

    local branch = {}

    --The DecisionBranch's data members.
    branch.name = name
    branch.children = {}
    branch.evaluator = nil
    branch.type = BRANCH_TYPE

    local function addChild(self, child, index)
        --Add the child at the specified index, or as the last child.
        index = index or (#self.children + 1)
        table.insert(self.children, index, child)
    end

    local function setEvaluator(self, evaluator)
        --print(type(evaluator))
        self.evaluator = evaluator
    end

    local function evaluate(self)
        --Execute the branch's evaluator function, this must return a
        --numeric value which indicates what child should execute.
        local eval = self.evaluator:evaluate()
        if type(eval) == "boolean" then
            eval = (eval and 1 or 0) + 1
        end
        --print(self.name, eval)
        local choice = self.children[eval]
        if (choice.type == BRANCH_TYPE) then
            --Recursively evaluate children that are decisions
            --branches.
            return choice:evaluate()
        else
            --Return the leaf action.
            return choice
        end
    end

    --The DecisionBranch's accessor functions.
    branch.addChild = addChild
    branch.setEvaluator = setEvaluator
    branch.evaluate = evaluate

    return branch

end

return BehaviorTree