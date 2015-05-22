function class(def)
    local class = {}
    local parents = {}
    setmetatable(class, class)
    
    local function super(parent_class)
        if not parent_class then
            parent_class = parents[1]
            
            return setmetatable({}, {
                __ipairs    = function()        return ipairs(parent_class)              end,
                __pairs     = function()        return  pairs(parent_class)              end,
                __index     = function(t, name) return        parent_class[name]         end,
                __index_new = function(t, name, value)        parent_class[name] = value end
            })
        end
    end
    
    function class.__init(...) end
    function class.__call(...)
        local this = {}
        for k,v in pairs(class) do
            if type(v) == "function" then
                v = (function(func)
                    return function(...)
                        local t = _ENV.this
                        local s = _ENV.super
                        
                        _ENV.this  = this
                        _ENV.super = super
                        
                        local ret  = func(...)
                        
                        _ENV.this  = t
                        _ENV.super = s
                        
                        return ret
                    end
                end)(v)
            end
            this[k] = v
        end
        this.__class = class
        this.__init(...)
        return this
    end

    for i=1,math.huge do
        inherit, v = debug.getlocal(def, i)
        if not inherit then break end
        
        local parent_class = _G[inherit]
        for i=1,math.huge do
            local name, pclass = debug.getlocal(2,i,1)
            if not name then break
            elseif name == inherit then
                parent_class  = pclass
                break
            end
        end
        
        if parent_class  and type(parent_class) == 'table' then
            table.insert(parents, parent_class)
            for k,v in pairs(parent_class) do
                if k ~= "__call" then
                    class[k] = v
                end
            end
        else
            error(string.format('Class "%s" not valid.', name))
        end
    end
    
    class.__parents = parents

    local env = _ENV
    _ENV = setmetatable({}, {
        __index= function(t, name)
            local value = class[name]
            
            if value == nil then
                return env[name]
            else
                return value
            end
        end,
        __newindex =
            function(t, name, value)
                if name ~= "__call" then
                    class[name] = value
                end
            end,
    })
    env.pcall(def)
    _ENV = env
    
    return class
end

global  = true
Inherit = class(function()
    this_is_a_property_of_Inherit = true
    
    function __init()
        print('Inherit().__init()')
        this.init = true
    end
end)

Example = class(function(Inherit)
    print('Inherited property:', this_is_a_property_of_Inherit)
    print('Global variable:   ', global, '\n')
    
    function __init()
        print('Example().__init()')
        super().__init()
        print('this.init:', this.init)
    end
    
    function test(...)
        print(..., this.__init, '\n')
    end
end)

example = Example()
example.test('__init:')

example.property = 'I\'m a property of instance "example"'
print('example.property', example.property)
print('Example.property', Example.property)

--Output:
--  Inherited property:	true
--  Global variable:   	true	

--  Example().__init()
--  Inherit().__init()
--  this.init:	true
--  __init:	function: 0x1e68170	

--  example.property	I'm a property of instance "example"
--  Example.property	nil
