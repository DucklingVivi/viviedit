local directory = "viviedit/"
local url_base = "https://raw.githubusercontent.com/DucklingVivi/viviedit/refs/heads/main/"


local todownload = {
    "patterns.csv",
    "viviedit.lua",
    "vivicontext.lua",
    "vividownload.lua"
}


for _, value in pairs(todownload) do
    local url = url_base .. value
    local request = http.get(str, nil, true)
    local file = fs.open(directory .. value, "wb")
    file.write(file.readAll())
    file.close()
end



