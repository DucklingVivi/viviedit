local completion = require "cc.shell.completion"



shell.setCompletionFunction("viviedit/viviedit.lua", completion.build(completion.file))

shell.setAlias("spelledit", "viviedit/viviedit.lua")
shell.setAlias("vupdate", "viviedit/vividownload.lua")

settings.load(".settings")
