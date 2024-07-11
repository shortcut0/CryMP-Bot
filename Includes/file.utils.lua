--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful string utils for lua
--
--=====================================================

-------------------
fileutils = {
	version = "1.0",
	author = "shortcut0",
	description = "all kinds of fileutils utiliy functions that might come in handy",
	requires = "lua.utils.lua",
}

---------------------------

fileutils.LUA_5_3 = false

---------------------------

FO_READ = "r"
FO_READPLUS = "r+"
FO_WRITE = "w"
FO_OVERWRITE = "w+"
FO_APPEND = "a"

---------------------------
-- fileutils.fixpath

fileutils.fixpath = function(sFile, sSlash)

	------------
	local sFixed = string.new(sFile)
	sFixed = string.gsubex(sFixed, { "/", "\\" }, (sSlash or "/"))
	sFixed = string.ridtrailex(sFixed, "/", "\\")

	------------
	return sFixed
end

---------------------------
-- fileutils.close

fileutils.close = function(sFile)
	if (not fileutils.ishandle(sFile)) then
		return true end
	
	------------
	sFile:close()
	
	------------
	return true
end

---------------------------
-- fileutils.open

fileutils.open = function(sFile, iMode)
	local hFile = io.open(sFile, checkVar(iMode, FO_READ))
	if (not hFile) then
		return end
	
	------------
	return hFile
end

---------------------------
-- fileutils.delete

fileutils.delete = function(sFile)

	------------
	os.execute(string.format([[
		IF EXIST "%s" DEL "%s"
	]], sFile, sFile))
	
	------------
	return true
end

---------------------------
-- fileutils.ishandle

fileutils.ishandle = function(hParam)
	return (type(hParam) == "userdata" and string.match(tostring(hParam), "^file %((.+)%)$"))
end

---------------------------
-- fileutils.fileexists

fileutils.fileexists = function(sFile)
	if (not isString(sFile)) then
		return false end
		
	----------
	local hFile = fileutils.open(sFile, FO_READ)
	if (hFile) then
		fileutils.close(hFile)
		return true end
	
	----------
	return false
end

---------------------------
-- fileutils.size

fileutils.size = function(sFile)
		
	---------
	if (fileutils.ishandle(sFile)) then
		return (sFile:seek("end")) end
	
	---------
	local hFile = fileutils.open(sFile, FO_READ)
	if (not hFile) then
		return 0 end
		
	---------
	local fSize = hFile:seek("end")
	fileutils.close(hFile)

	---------
	return (fSize)
end

---------------------------
-- fileutils.lines

fileutils.lines = function(sFile)
		
	---------
	if (fileutils.ishandle(sFile)) then
		return (fileutils.countlines(sFile)) end
	
	---------
	local hFile = fileutils.open(sFile, FO_READ)
	if (not hFile) then
		return 0 end
		
	---------
	local iLines = (fileutils.countlines(hFile))
	fileutils.close(hFile)

	---------
	return (iLines)
end

---------------------------
-- fileutils.countlines

fileutils.countlines = function(hFile)
		
	---------
	if (not fileutils.ishandle(hFile)) then
		return 0 end
	
	---------
	local iLines = 0
	for i in hFile:lines() do
		iLines = iLines + 1 end

	---------
	return (iLines)
end

---------------------------
-- fileutils.read

fileutils.read = function(sFile)
		
	---------
	if (fileutils.ishandle(sFile)) then
		return (sFile:read("*all")) end
	
	---------
	local hFile = fileutils.open(sFile, FO_READ)
	if (not hFile) then
		return nil end
		
	---------
	local sData = hFile:read("*all")
	fileutils.close(hFile)

	---------
	return (sData)
end

---------------------------
-- fileutils.flush

fileutils.flush = function(sFile)
		
	---------
	if (not fileutils.fileexists(sFile)) then
		return false end
		
	---------
	local hFile = fileutils.open(sFile, FO_OVERWRITE)
	if (not hFile) then
		return nil end
		
	---------
	fileutils.close(hFile)

	---------
	return true
end

---------------------------
-- fileutils.getfiles

fileutils.getfiles = function(sPath)

	---------
	local sPath = checkVar(sPath, string.getworkingdir())
	-- local sFiles = string.getval(string.format("IF EXIST \"%s\\*\" DIR \"%s\" /B /ON /A-D", sPath, sPath), fileutils.LUA_5_3)
	-- local sFiles = string.getval(string.format([[2>&1 >nul WHERE "%s:*" >nul && (DIR "%s" /B /ON /A-D) || (ECHO ?dir_empty?)]], sPath, sPath), fileutils.LUA_5_3)
	-- local sFiles = string.getval(string.format([[2>&1>nul CD "%s" && (DIR "%s" /B /ON /A-D) || (ECHO ?dir_empty?)]], sPath, sPath), fileutils.LUA_5_3)
	-- local sFiles = string.getval(string.format([[>nul WHERE "%s:*">nul && (DIR "%s" /B /ON /A-D) || (ECHO ?dir_empty?)]], sPath, sPath), fileutils.LUA_5_3)
	local sFiles = string.getval(string.format([[@FOR /f "tokens=*" %%a in ('DIR /B /ON /A-D "%s" 2^>NUL') do @ECHO %%a]], sPath), fileutils.LUA_5_3)

	---------
	if (string.find(sFiles, "%?dir_empty%?$") or string.empty(sFiles)) then
		return {} end

	---------
	return string.split(sFiles, "\n")
end

---------------------------
-- fileutils.getfiles

fileutils.getfolders = function(sPath)

	---------
	local sPath = checkVar(sPath, string.getworkingdir())
	local sFolders = string.getval(string.format("IF EXIST \"%s\\*\" DIR \"%s\" /B /ON /AD", sPath, sPath), fileutils.LUA_5_3)

	---------
	return string.split(sFolders, "\n")
end

---------------------------
-- fileutils.getdir

fileutils.getdir = function(sPath)

	---------
	local sPath = checkVar(sPath, string.getworkingdir())
	local sFiles = string.getval(string.format("IF EXIST \"%s\\*\" DIR \"%s\" /B /ON", sPath, sPath), fileutils.LUA_5_3)

	---------
	return string.split(sFiles, "\n")
end

---------------------------
-- fileutils.pathexists

fileutils.pathexists = function(sPath)

	local bExists = (string.getval(string.format([[IF EXIST "%s" (ECHO 1 {file_out}) ELSE (ECHO 0 {file_out})]], sPath), fileutils.LUA_5_3, fileutils.LUA_5_3) == "1")

	---------
	return bExists

	---------
	-- local sTempFile = string.makefilename(string.gettempdir() .. "\\file_check_test")
	-- os.execute(string.format([[
		-- IF EXIST "%s" (ECHO 1 >> "%s") ELSE (ECHO 0 >> "%s")
	-- ]], sPath, sTempFile, sTempFile))

	-------
	-- local sResult = fileutils.read(sTempFile)

	-------
	-- fileutils.delete(sTempFile)
	
	---------
	-- return (string.match(sResult, "1") == "1")
end

---------------------------
-- fileutils.getattrib

fileutils.getattrib = function(sPath)

	---------
	if (not fileutils.pathexists(sPath)) then
		return false end

	---------
	local sAttributes = string.getval(string.format([[
		ATTRIB "%s"
	]], sPath), fileutils.LUA_5_3)
	
	---------
	sAttributes = string.sub(sAttributes, 1, 21)
	sAttributes = string.gsub(sAttributes, "%s", "")

	---------
	return (sAttributes)
end

---------------------------
-- fileutils.isfile

fileutils.isfile = function(sPath)

	---------
	if (not fileutils.pathexists(sPath)) then
		return false end

	---------
	return (not fileutils.isdir(sPath))
end

---------------------------
-- fileutils.isdir

fileutils.isdir = function(sPath)

	---------
	if (not fileutils.pathexists(sPath)) then
		return false end

	---------
	local bDirectory = (string.getval(string.format([[IF EXIST "%s\*" (ECHO 1 {file_out}) ELSE (ECHO 0 {file_out})]], sPath), fileutils.LUA_5_3, fileutils.LUA_5_3) == "1")

	---------
	return bDirectory
end

---------------------------
-- fileutils.size_dir

fileutils.size_dir = function(sPath, bRecursive)
	
	---------
	local sPath = string.ridtrailex(sPath, "\\", "/")
	
	---------
	if (not fileutils.pathexists(sPath)) then
		return (0) end

	---------
	if (not fileutils.isdir(sPath)) then
		return fileutils.size(sPath) end

	---------
	local aFolders = fileutils.getfolders(sPath)
	local aFiles = fileutils.getfiles(sPath)
	
	---------
	local iTotalSize = 0
	if (bRecursive) then
		for i, sFolder in pairs(aFolders) do
			iTotalSize = (iTotalSize + (fileutils.size_dir(sPath .. "\\" .. sFolder, true)))
		end
	end
	
	---------
	for i, sFile in pairs(aFiles) do
		iTotalSize = (iTotalSize + fileutils.size(sPath .. "\\" .. sFile)) 
	end
	
	---------
	return (iTotalSize)
end

---------------------------
-- fileutils.getdir_tree

fileutils.getdir_tree = function(sPath, bFullPath)

	-- print("Dir-> " .. sPath)
	if (not sPath) then
		return end
	
	---------
	local sPath = fileutils.fixpath(sPath)
	if (not fileutils.pathexists(sPath)) then
		return {} end

	---------
	if (not fileutils.isdir(sPath)) then
		return { sPath } end

	---------
	local aFolders = fileutils.getfolders(sPath)
	local aFiles = fileutils.getfiles(sPath)
	
	---------
	local aFolderData = {}
	
	---------
	for i, sFile in pairs(aFiles) do
		-- print("File " .. sPath .. " -> " .. sFile)
		if (bFullPath) then
			table.insert(aFolderData, sPath .. "/" .. sFile) else
			table.insert(aFolderData, sFile) end
	end
	
	---------
	for i, sFolder in pairs(aFolders) do
		-- print("Folder " .. sPath .. " -> " .. sFolder)
		aFolderData[sFolder] = fileutils.getdir_tree((sPath .. "/" .. sFolder), true)
	end

	---------
	return aFolderData
end

---------------------------
-- fileutils.getname

fileutils.getname = function(sFile)

	---------
	--- "^.*\\(.*)", "^.*/(.*)"
	local sName = string.matchex(sFile, "([^\\/]+)%.([^%.]+)$")
	return sName
end

---------------------------
-- fileutils.getnameex

fileutils.getnameex = function(sFile)

	---------
	return (string.matchex(sFile, "^.*\\(.*)", "^.*/(.*)"))
end

---------------------------
-- fileutils.getextension

fileutils.getextension = function(sFile)

	---------
	return string.getfileextension(sFile)
end

---------------------------
-- fileutils.getpath

fileutils.getpath = function(sFile)

	---------
	return (checkVar(string.matchex(sFile, "^(.*)\\.*", "^(.*)/.*"), sFile) .. "\\")
end

-------------------

isFile = fileutils.ishandle
IsFile = fileutils.ishandle

FileGetExtension = fileutils.getextension
FileGetName = fileutils.getname
FileGetNameEx = fileutils.getnameex
FileGetPath = fileutils.getpath
FileGetSize = fileutils.size
FileRead = fileutils.read
FileFlush = fileutils.flush
FileIsFile = fileutils.isfile
FileDelete = fileutils.delete
FileExsist = fileutils.fileexists
FileGetLines = fileutils.lines

PathExists = fileutils.pathexists
PathIsFile = fileutils.isfile
PathIsDir = fileutils.isdir

DirGetFiles = fileutils.getfiles
DirGetFolders = fileutils.getfolders
DirGetAll = fileutils.getdir
DirGetTree = fileutils.getdir_tree
DirGetSize = fileutils.size_dir

-------------------
return fileutils