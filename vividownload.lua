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
    local request = http.get(url, nil, true)
    local file = fs.open(directory .. value, "wb")
    file.write(request.readAll())
    file.close()
end



