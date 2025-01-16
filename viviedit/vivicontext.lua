local vivicontext = {}
vivicontext.accumulator_types = {}
vivicontext.patterns = {}
vivicontext.argpatterns = {}
vivicontext.defs = {}
vivicontext.iotas = {}
vivicontext.utils = {}




local function addIota(name, builder)
    local iota = {}
    iota.build = builder
    vivicontext.iotas[name] = iota
end

local function addUtil(name, builder)
    local util = {}
    util.execute = builder
    vivicontext.utils[name] = util
end

local function addArgPattern(name, builder)
    local util = {}
    util.execute = builder
    vivicontext.argpatterns[name] = util
end



addArgPattern("Numerical Reflection", function(self, args, ctx)
    local number = tonumber(args[1])
    local angles = "aqaa"
    if(number < 0) then
        angles = "dedd"
    end

    target = math.abs(number)
    
    while(target > 0) do
        if(target >= 10) then
            angles = angles .. "e"
            target = target - 10
        elseif(target >= 5) then
            angles = angles .. "q"
            target = target - 5
        elseif(target >= 1) then
            angles = angles .. "w"
            target = target - 1
        else
            break
        end
    end


    return {startDir = "EAST", angles = angles}
end)

addArgPattern("Bookkeeper's Gambit", function(self, args, ctx)
    local first = true
    local pattern = args[1]:gsub("[^%-v]+", "")
    local angles = ""
    --iterate through pattern and build angles
    for i = 1, #pattern do
        prev = pattern:sub(i-1,i-1)
        if(pattern:sub(i,i) == "v") then
            if(first) then
                angles = angles .. "a"
                first = false
            else
                if(prev == "v") then
                    angles = angles .. "da"
                else
                    angles = angles .. "ea"
                end
            end
        else
            if(first) then
                first = false
            else
                if(prev == "v") then
                    angles = angles .. "e"
                else
                    angles = angles .. "w"
                end
            end
        end
    end
    return {startDir = "EAST", angles = angles}
end)

addUtil("def", function(self, args, ctx)
    vivicontext.defs[args[1]] = args[2]
end)

addUtil("file", function(self, args, ctx)
    local file = args[1]
    if not (file:find(".hexpattern")) then
        file = file .. ".hexpattern"
    end
    local value = ctx:new():open_file(file):execute():finish()
    for _, val in pairs(value.value) do
        table.insert(ctx.value, val)
    end
end)


addIota("num", function(self,val)
    return tonumber(val[1])
end)
addIota("str", function(self,val)
    return val[1]
end)

addIota("null", function(self,val)
    return { null = true }
end)

addIota("garbage", function(self,val)
    return { garbage = true }
end)

addIota("bool", function(self,val)

    if(val[1] == "true" or val[1] == "false") then
        return val[1] == "true"
    else
        return {garbage = true}
    end
end)

addIota("vec", function(self,val)
    return { x = tonumber(val[1]), y = tonumber(val[2]), z = tonumber(val[3])}
end)

addIota("entity", function(self,val)
    local uuid = (val[1]:gsub("^%s*(.-)%s*$", "%1"))
    return { entity = uuid }
end)

addIota("pattern", function(self,val)
    local startDir = (val[1]:gsub("^%s*(.-)%s*$", "%1"))
    local angles = (val[2]:gsub("^%s*(.-)%s*$", "%1"))
    return { startDir = startDir, angles = angles }
end)

addIota("iota_type", function(self,val)
    local type1 = (val[1]:gsub("^%s*(.-)%s*$", "%1"))
    return { iotaType = type1 }
end)

addIota("entity_type", function(self,val)
    local type1 = (val[1]:gsub("^%s*(.-)%s*$", "%1"))
    return { entityType = type1 }
end)



local function loadDefaultPatterns()
    local patterns = {}
    local file = fs.open("viviedit/patterns.csv", "r")

    if file then
        local first = file.readLine()
        local labels = {}
        for label in string.gmatch(first, '([^,]+)') do
            table.insert(labels, label)
        end

        for line in file.readLine do
            local vals = {}
            for val in string.gmatch(line, '([^,]+)') do
                table.insert(vals, val)
            end
            local pattern = {}
            for n, label in pairs(labels) do
                pattern[label] = vals[n]
            end
            patterns[pattern["translation"]] = pattern
        end
        file.close()
    end
    return patterns
end

vivicontext.patterns = loadDefaultPatterns()



vivicontext.patterntoiota = function(pattern)
    if(pattern == nil) then
        return nil
    end
    if(pattern.direction == "GREAT") then
        return "_G" .. pattern.translation;
    end
    local val = {
        startDir = pattern.direction,
        angles = pattern.pattern
    }
    return val
end

local accumulator = {}

function accumulator:new(name)
    local o = {}
    o.name = name
    function o:new()
        local o2 = {}
        for k, v in pairs(self) do
            o2[k] = v
        end
        return o2
    end

    function o:execute(input)
        return false
    end

    function o:setExecute(func)
        self.execute = func
        return self
    end
    function o:setValue(prop, value)
        if(value == nil) then
            value = prop
            prop = "value"
        end
        self[prop] = value
        return self
    end
    function o:getValue(prop)
        return self[prop or "value"]
    end
    function o:finalize()
        vivicontext.accumulator_types[name] = self
    end
    return o;
end


accumulator:new("string_accumulator"):setExecute(function(self, ctx)
    self.value = 0
end):finalize()


local function evaluate_definition(accum, ctx)
    accum.value = (accum.value:gsub("^%s*(.-)%s*$", "%1"))
    local def = vivicontext.defs[accum.value]
    if(def) then
        local path = ".temp.".."vivicontext" .. tostring(ctx.depth + 1) .. ".hexpattern"
        file = fs.open(path, "w")
        file.write(def)
        file.close()
        local newacc = ctx:new():switch_type("scan_accumulator")
        newacc:open_file(path)
        newacc.depth = ctx.depth + 1
        if(accum.args ~= nil) then
            for k, val in pairs(accum.args) do
                newacc.toreplace[k] = val
            end
        end 
        newacc:execute():finish()
        for _, val in pairs(newacc.value) do
            table.insert(ctx.value, val)
        end
        fs.delete(path)
    end 
    ctx:switch_type("scan_accumulator")
end

accumulator:new("definition_arg_accumulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        evaluate_definition(self,ctx)
        return
    elseif(ctx.char:match("%(")) then
        local newacc = ctx:new(true):switch_type("definition_scan_accumulator")
        newacc.accum:setValue("depth", 0)
        newacc.accum:setValue("buffer", "")
        newacc.raw = false
        newacc:set_file(ctx.file)
        newacc:execute()
        table.insert(self.args, newacc.value)
    elseif(ctx.char:match("%\n")) then
        evaluate_definition(self,ctx)
        return
    elseif(ctx.char:match("[%s]]")) then
        evaluate_definition(self,ctx)
        return
    end
    ctx:read_next()
end):finalize()
accumulator:new("definition_accumulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        evaluate_definition(self,ctx)
        ctx.processing = false
        return
    elseif(ctx.char:match("[%w_%\']+")) then
        self.value = self.value .. ctx.char
        ctx:read_next()
       return
    elseif(ctx.char:match("%(")) then
        ctx:switch_type("definition_arg_accumulator")
        ctx.accum:setValue(self.value)
        ctx.accum:setValue("args",{})
        return
    elseif(ctx.char:match("%\n")) then
        evaluate_definition(self,ctx)
        return
    elseif(ctx.char:match("[%s%]]")) then
        evaluate_definition(self,ctx)
        return
    else
    end

    ctx:read_next()

end):finalize()

accumulator:new("comment_accummulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%\n")) then
        ctx:switch_type("scan_accumulator")
        ctx:read_next()
        return
    end
    ctx:read_next()
end):finalize()



accumulator:new("pattern_args_accumulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return 
    elseif(ctx.char:match("[%w%s%\'%.%-]+")) then
        self.buffer = self.buffer .. ctx.char
        ctx:read_next()
        return
    elseif(ctx.char:match("%)")) then
        table.insert(self.args, self.buffer)
        local iota = vivicontext.argpatterns[self.value]
        if(iota) then
            local result = iota:execute(self.args, ctx)
            table.insert(ctx.value, result)
        end
        ctx:switch_type("scan_accumulator")
        ctx:read_next()
        return
    end
    ctx:read_next()
end):finalize()

accumulator:new("pattern_accumulator"):setExecute(function(self, ctx)
    local function finish()
        ctx:switch_type("scan_accumulator")
        self.value = (self.value:gsub("^%s*(.-)%s*$", "%1"))
        local iota = vivicontext.patterns[self.value]
        if(iota)then
            table.insert(ctx.value, vivicontext.patterntoiota(iota))
        end
    end
    if(ctx.char == nil) then
        ctx.processing = false
        finish()
        return
    elseif(ctx.char:match("%\n")) then
        finish()
        return
    elseif(ctx.char:match("[%w:%+%-%s%\']+")) then
        self.value = self.value .. ctx.char
        ctx:read_next()
        return
    elseif(ctx.char:match("%(")) then
        ctx:switch_type("pattern_args_accumulator")
        ctx.accum:setValue(self.value)
        ctx.accum:setValue("args",{})
        ctx.accum:setValue("buffer","")
        ctx:read_next()
        return
    else
        finish()
        return
    end

    ctx:read_next()
end):finalize()


accumulator:new("list_accumulator"):setExecute(function(self,ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return 
    end
    local newacc = ctx:new(true):switch_type("scan_accumulator")
    newacc:set_file(ctx.file)
    newacc:read_next()
    newacc:execute()
    table.insert(ctx.value, newacc.value)
    ctx:switch_type("scan_accumulator")
    ctx:read_next()
end):finalize()

accumulator:new("iotas_args_accumulator"):setExecute(function(self,ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return 
    elseif(self.escape)then
        self.buffer = self.buffer .. ctx.char
        self.escape = false
        ctx:read_next()
        return
    elseif(ctx.char:match("\\")) then
        self.escape = true
        ctx:read_next()
        return
    elseif(ctx.char:match("%,")) then
        table.insert(self.args, self.buffer)
        self.buffer = ""
        ctx:read_next()
        return
    elseif(ctx.char:match("[%w%s%%/\'%-%._:]+")) then
        self.buffer = self.buffer .. ctx.char
        ctx:read_next()
        return
    elseif(ctx.char:match("%)")) then
        table.insert(self.args, self.buffer)
        local iota = vivicontext.iotas[self.value]
        if(iota) then
            table.insert(ctx.value,iota:build(self.args))
        end
        ctx:switch_type("scan_accumulator")
        ctx:read_next()
        return
    end
    ctx:read_next()
end):finalize()
accumulator:new("iotas_accumulator"):setExecute(function(self,ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return 
    elseif(ctx.char:match("[%w%_]")) then
        self.value = self.value .. ctx.char
        ctx:read_next()
        return
    elseif(ctx.char:match("%(")) then
        ctx:switch_type("iotas_args_accumulator")
        ctx.accum:setValue(self.value)
        ctx.accum:setValue("args",{})
        ctx.accum:setValue("buffer","")
        ctx:read_next()
        return
    else
        local iota = vivicontext.iotas[self.value]
        if(iota) then
            table.insert(ctx.value,iota:build(nil))
        end
        ctx:switch_type("scan_accumulator")
        return 
    end
    ctx:read_next()
end):finalize()

accumulator:new("carrot_accumulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%>")) then
        table.insert(ctx.value, vivicontext.patterntoiota(vivicontext.patterns["Flock's Disintegration"]))
        ctx:switch_type("scan_accumulator")
        ctx:read_next()
        return
    else
        ctx:throw_error("Unfinished Carrot")
        ctx:switch_type("scan_accumulator")
    end
end):finalize()


accumulator:new("definition_scan_accumulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%(")) then
        self.depth = self.depth + 1
    elseif(ctx.char:match("%)")) then
        self.depth = self.depth - 1
        if(self.depth < 0) then
            ctx.processing = false
            ctx.value = self.buffer
            return
        end
    end
    self.buffer = self.buffer .. ctx.char
    ctx:read_next()
end):finalize()

accumulator:new("util_body_accumulator"):setExecute(function(self,ctx)
    local function commit()
        ctx:switch_type("scan_accumulator")
        vivicontext.utils[self.value]:execute(self.args, ctx)
    end
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%(")) then
        local newacc = ctx:new():switch_type("definition_scan_accumulator")
        newacc.accum:setValue("depth", 0)
        newacc.accum:setValue("buffer", "")
        newacc.raw = true
        newacc:set_file(ctx.file)
        newacc:execute()
        table.insert(self.args, newacc.value)
        ctx:switch_type("scan_accumulator")
        ctx:read_next()
        commit()
        return
    else
        commit();
    end
end):finalize()

accumulator:new("util_arg_accumulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%,")) then
        table.insert(self.args, self.buffer)
        self.buffer = ""
        ctx:read_next()
        return
    elseif(ctx.char:match("%)")) then
        table.insert(self.args, self.buffer)
        local util = vivicontext.defs[self.value]
        ctx:switch_type("util_body_accumulator")
        ctx.accum:setValue(self.value)
        ctx.accum:setValue("args",self.args)
        ctx:read_next()
        return
    elseif(ctx.char:match("[%w%s%\'%._]+")) then
        self.buffer = self.buffer .. ctx.char
        ctx:read_next()
        return
    end
    ctx:read_next()
end):finalize()

accumulator:new("util_accummulator"):setExecute(function(self, ctx)
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%\n")) then
        ctx:switch_type("scan_accumulator")
        ctx:read_next()
        return
    elseif(ctx.char:match("[%w%s%\']+")) then
        self.value = self.value .. ctx.char
        ctx:read_next()
        return
    elseif(ctx.char:match("%(")) then
        ctx:switch_type("util_arg_accumulator")
        ctx.accum:setValue(self.value)
        ctx.accum:setValue("args",{})
        ctx.accum:setValue("buffer","")
        ctx:read_next()
        return
    end
    ctx:read_next()
end):finalize()


local Introspection = vivicontext.patterntoiota(vivicontext.patterns["Introspection"])
local Retrospection = vivicontext.patterntoiota(vivicontext.patterns["Retrospection"])

accumulator:new("scan_accumulator"):setExecute(function(self, ctx)
    local function finish()
        ctx.processing = false
    end
    self.value = self.value or ""
    if(ctx.char == nil) then
        ctx.processing = false
        return
    elseif(ctx.char:match("%[")) then
        ctx:switch_type("list_accumulator")
        return
    elseif(ctx.char:match("%$")) then
        ctx:switch_type("definition_accumulator").accum:setValue("")
        ctx:read_next()
        return 
    elseif(ctx.char:match("%@")) then
        ctx:switch_type("iotas_accumulator").accum:setValue("")
        ctx:read_next()
        return
    elseif(ctx.char:match("[%)%]]"))then
        ctx.processing = false
        return
    elseif(ctx.char:match("%w")) then
        ctx:switch_type("pattern_accumulator").accum:setValue("")
        return
    elseif(ctx.char:match("%>")) then
        ctx:switch_type("carrot_accumulator")
        ctx:read_next()
        return
    elseif(ctx.char:match("%{")) then
        table.insert(ctx.value, Introspection)
        ctx:read_next()
        return
    elseif(ctx.char:match("%}")) then
        table.insert(ctx.value, Retrospection)
        ctx:read_next()
        return
    elseif(ctx.char:match("%-")) then
        ctx:switch_type("comment_accummulator")
        ctx:read_next()
        return
    elseif(ctx.char:match("%#")) then
        ctx:switch_type("util_accummulator").accum:setValue("")
        ctx:read_next()
        return
    else
        ctx:read_next()
        return
    end
    
end):finalize()



local function parser()
    local o = {}

    function o:switch_type(type_str)
        self.accum = vivicontext.accumulator_types[type_str]:new()
        return self
    end


    function o:read_next()
        buffer = ""
        if(self.overridebuffer[0] ~= nil) then
            self.char = self.overridebuffer[0]:sub(1,1)
            self.overridebuffer[0] = self.overridebuffer[0]:sub(2)
            if(self.overridebuffer[0] == "") then
                self.overridebuffer[0] = nil
            end
            return self.char
        end
        self.char = self.file.read(1)
        if(self.char == "<" and not self.raw) then
            self.char = self.file.read(1)
            repeat
                buffer = buffer .. self.char
                self.char = self.file.read(1)
            until(self.char == ">")
            replacer = self.toreplace[tonumber(buffer)]
            if(replacer) then
                self.overridebuffer[0] = replacer
                return self:read_next()
            else
                self.overridebuffer[0] = "<" .. buffer .. ">"
                return self:read_next()
            end
        end
        return self.char
    end

    function o:throw_error(error)
        self.error = error
    end

    function o:new(override)
        local runner = {
            file = nil,
            value = {},
            accum = nil,
            char = nil,
            processing = false,
            depth = 0,
            error = nil,
            toreplace = {},
            overridebuffer = {},
            raw = false
        }

        if(self.toreplace) then
            for k, v in pairs(self.toreplace) do
                runner.toreplace[k] = v
            end
        end
        if(self.overridebuffer and override) then
            runner.overridebuffer = self.overridebuffer
        end
        if(self.depth) then
            runner.depth = self.depth
        end

        setmetatable(runner, {__index = function(this, key)
            return o[key]
        end})
        runner:switch_type("scan_accumulator")
        runner.accum:setValue("value", {})
        return runner;
    end
    function o:open_file(file_str)
        self.file = fs.open(file_str, "r")
        return self
    end
    function o:set_file(file)
        self.file = file
        return self
    end
    function o:execute()
        self.processing = true;
        if(self.char == nil) then
            self:read_next()
        end
        while (self.processing) do
            self.accum:execute(self)
            if(self.error) then
                self.processing = false
                print(self.error)
            end
        end
        return self;
    end
    function o:finish()
        self.file.close()
        return self
    end
    return o:new()
end

vivicontext.parser = parser()

return vivicontext;
