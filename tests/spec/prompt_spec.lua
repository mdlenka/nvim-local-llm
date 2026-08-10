local prompt = require("local_llm.prompt")
local eq = assert.are.same

describe("prompt", function()
  it("system prompt mentions the invariant", function()
    assert.truthy(prompt.system_prompt:match("MUST START WITH the prefix"))
    assert.truthy(prompt.system_prompt:match("NEVER return a suffix"))
  end)
  it("user prompt contains context and prefix", function()
    local p = prompt.build_user_prompt("The muon", "scat")
    assert.truthy(p:match("The muon"))
    assert.truthy(p:match("scat"))
  end)
end)
