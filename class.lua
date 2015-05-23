function class(def)
    local class = {}
    local parents = {}
    
    local wraps
    local function super(parent_class)
        if not parent_class then
            parent_class = parents[1]
        end
        
        local this = this
        local that = {}
        for k,v in pairs(parent_class) do
            that[k] = type(v) == 'function' and wraps(this, v) or v
        end
        
        return setmetatable(that, that)
    end
    
    function wraps(this, func)
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
    end
    
    function class.__init() end
    local class_wrap = setmetatable({}, {
        __ipairs    = function()        return ipairs(class)              end,
        __pairs     = function()        return  pairs(class)              end,
        __index     = function(t, name) return        class[name]         end,
        __index_new = function(t, name, value)        class[name] = value end,
        __call      = function(...)
            local this = {}
            for k,v in pairs(class) do
                this[k] = type(v) == 'function' and wraps(this, v) or v
            end
            
            this.__class = class
            this.__init(...)
            
            return setmetatable(this, this)
        end
    })

    for i=1,math.huge do
        inherit, v = debug.getlocal(def, i)
        if not inherit then break end
        
        local parent_class = _ENV[inherit]
        if parent_class  and type(parent_class) == 'table' then
            table.insert(parents, parent_class)
            for k,v in pairs(parent_class) do
                class[k] = v
            end
        else
            error(string.format('Class "%s" not valid.', name))
        end
    end

    local env = _ENV
    _ENV = setmetatable({}, {
        __index= function(t, name)
            local  value  = class[name]
            return value ~= nil and value or env[name]
        end,
        __newindex = function(t, name, value)
                class[name] = value
            end,
    })
    
    env.pcall(def, env.table.unpack(parents))
    _ENV = env
    
    return class_wrap
end

global  = true
Inherit = class(function()
    this_is_a_property_of_Inherit = true
    
    function __init()
        print('Inherit().__init()')
        this.init = true
    end
    
    function __call()
        print('Yay! You\'re calling for me :) init:', this.init, '\n')
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
example()

example.property = 'I\'m a property of instance "example"'
print('example.property', example.property)
print('Example.property', Example.property)

--    Inherited property:	true
--    Global variable:   	true	

--    Example().__init()
--    Inherit().__init()
--    this.init:	true
--    __init:	function: 0x15dd5f0	

--    Yay! You're calling for me :) init:	true	

--    example.property	I'm a property of instance "example"
--    Example.property	nil
