local ADDON_NAME, A = ...
--[[
@non-self
--]]
A.Template = {}

--- Parses a template string and replaces placeholders with values from a data table.
-- Placeholders are in the format `{{key}}`.
-- @param template The template string.
-- @param data A table where keys correspond to placeholders in the template.
-- @return The processed string with placeholders replaced.
function A.Template:Parse(template, data)
    if not template or not data then
        return ""
    end

    -- Loop to handle nested replacements, though simple replacement is the primary use case.
    -- Guards against simple cases where a replacement itself contains a placeholder.
    local processedString = template
    for _ = 1, 5 do -- Limit iterations to prevent infinite loops
        local replacements_found = false
        processedString = string.gsub(processedString, "{{(.-)}}", function(key)
            local value = data[key]
            if value ~= nil and value ~= "" then
                replacements_found = true
                return tostring(value)
            end
            return "" -- Return empty string for missing or empty values to collapse them.
        end)
        if not replacements_found then
            break
        end
    end

    return processedString
end
