local tArgs = { ... }
if #tArgs == 0 then
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usage: " .. programName .. " <path>")
    return
end



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

local patterns = loadDefaultPatterns()




local ret = {}

ret["startDir"] = patterns["Craft Artifact"].direction
ret["angles"] = patterns["Craft Artifact"].pattern

local port = peripheral.wrap("bottom")
port.writeIota(ret)