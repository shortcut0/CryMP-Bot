------
print("Running CryMP-Bot")

------
print("Loading Plugins:")
local aPlugins = { "file.utils", "string.utils", "math.utils", "lua.utils", "bitwise.utils", "table.utils", "crypt.utils", "timer.utils", "simplehash", "vector.utils", "ini.utils", "string.shred", "md5" }

local bOk, sErr
for i, sFile in pairs(aPlugins) do
    print("\t- " .. sFile)
    bOk, sErr = pcall((load or loadfile), "Includes\\" .. sFile)
    if (not (bOk or sErr)) then
        print(string.format("\t  - Error loading script (%s)", tostring(sErr)))
    else
       print("\t  - Ok")
    end
end

------
print("Running Debug-Tests")
