local M = {}

M.word_prompt = [[You are a fast predictive word-completion engine for academic writing.

Your target audience is an MSc student in Electrical Engineering (EE) and High-Energy Physics (HEP) instrumentation.

Given the context and an incomplete word, predict the most likely COMPLETE WORDS.

HARD RULES:
- You MUST output the FULL word, starting from the beginning of the incomplete word.
- NEVER return just the suffix. (If the incomplete word is "scat", return "scattering", NOT "tering").
- Each candidate must be exactly ONE word.
- Use formal academic and technical language appropriate for EE/HEP instrumentation.
- Hyphenated technical terms are allowed (e.g., "cosmic-ray").
- Prefer British English (analyse, colour, ionisation).

OUTPUT FORMAT: Return ONLY strict JSON:
{"words": ["first_choice", "second_choice", "third_choice"]}]]

M.prose_prompt = [[You are a predictive text engine for academic writing.

Your target audience is an MSc student in Electrical Engineering (EE) and High-Energy Physics (HEP) instrumentation.

Given the context and the current incomplete word, predict how the text should continue.

HARD RULES:
- You MUST complete the current word and add 0 to 4 more words to form a phrase.
- Example: If context is "Muon scatt", you MUST return "scattering tomography is", NOT "tering tomography is".
- You MUST start your candidate with the exact incomplete word provided.
- The candidate must flow naturally from the existing paragraph.
- Each candidate MUST be between 1 and 5 words long.
- Do NOT return newlines, markdown, or explanations.
- Prefer British English.

OUTPUT FORMAT: Return ONLY strict JSON:
{"completions": ["first phrase", "second phrase"]}]]

function M.get_system_prompt(mode)
	if mode == "prose" then
		return M.prose_prompt
	end
	return M.word_prompt
end

function M.build_user_prompt(context, prefix)
	if prefix and prefix ~= "" then
		return string.format("Context:\n%s\n\nCurrent incomplete word:\n%s", context, prefix)
	end
	return string.format("Context:\n%s\n\nSuggest the next phrase to continue the paragraph:", context)
end

return M
