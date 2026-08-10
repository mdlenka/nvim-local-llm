local validate = require("local_llm.validate")
local eq = assert.are.same

local opts_hyph = { allow_hyphenated = true  }
local opts_no   = { allow_hyphenated = false }

describe("validate.validate_candidate", function()
  it("accepts a full word that starts with prefix", function()
    eq("scattering", validate.validate_candidate("scattering", "scat", opts_hyph))
  end)
  it("rejects a suffix", function()
    assert.is_nil(validate.validate_candidate("tering", "scat", opts_hyph))
  end)
  it("rejects a multi-word phrase", function()
    assert.is_nil(validate.validate_candidate("scattering angle", "scat", opts_hyph))
  end)
  it("rejects the prefix alone", function()
    assert.is_nil(validate.validate_candidate("scat", "scat", opts_hyph))
  end)
  it("accepts hyphenated technical terms when allowed", function()
    eq("radiation-length", validate.validate_candidate("radiation-length", "radiation", opts_hyph))
  end)
  it("rejects hyphenated terms when not allowed", function()
    assert.is_nil(validate.validate_candidate("radiation-length", "radiation", opts_no))
  end)
end)
