local contents_url = "https://api.github.com/repos/DucklingVivi/viviedit/contents/?ref=main"



local ignored_paths = {}
ignored_paths[".gitattributes"] = true
ignored_paths["README.md"]= true


local function get_contents(url)
    local response = http.get(url)
    local contents = response.readAll()
    response.close()
    local parsed = textutils.unserializeJSON(contents)
    for _, v in ipairs(parsed) do
        if not ignored_paths[v.path] then
            if v.type == "file" then
                local file_url = v.download_url
                local file_response = http.get(file_url)
                local file_contents = file_response.readAll()
                file_response.close()
                local file = fs.open(v.path, "w")
                file.write(file_contents)
                file.close()
            end
        end
    end
end


get_contents(contents_url)