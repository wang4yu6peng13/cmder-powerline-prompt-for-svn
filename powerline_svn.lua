-- Constants
local segmentColors = {
    clean = {
        fill = colorGreen,
        text = colorWhite
    },
    dirty = {
        fill = colorYellow,
        text = colorBlack
    },
    conflict = {
        fill = colorRed,
        text = colorWhite
    }
}

---
-- Finds out the name of the current branch
-- @return {false|svn branch name}
---
function get_svn_branch(svn_dir)
    local file = io.popen("svn info 2>nul")
    for line in file:lines() do
        local m = line:match("^URL:")
        if m then
            file:close()
            return line:sub(line:find("/")+1,line:len())
        end
    end
    file:close()

    return false
end

---
-- Gets the .git directory
-- copied from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
-- @return {bool} indicating there's a git directory or not
---
-- function get_git_dir(path)
-- MOVED INTO CORE

---
-- Gets the status of working dir
-- @return {bool} indicating true for clean, false for dirty
---
function get_svn_status()
    local file = io.popen("svn status -q")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()

    return true
end

---
-- Resolves closest directory location for specified directory.
-- Navigates subsequently up one level and tries to find specified directory
-- @param  {string} path    Path to directory will be checked. If not provided
--                          current directory will be used
-- @param  {string} dirname Directory name to search for
-- @return {string} Path to specified directory or nil if such dir not found
local function get_dir_contains(path, dirname)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end
        return prefix
    end

    -- Navigates up one level
    local function up_one_level(path)
        if path == nil then path = '.' end
        if path == '.' then path = clink.get_cwd() end
        return pathname(path)
    end

    -- Checks if provided directory contains git directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(path..'/'..specified_dir)
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .git directory here, then return current path
    if has_specified_dir(path, dirname) then
        return path..'/'..dirname
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = up_one_level(path)
        if parent_path == path then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

local function get_svn_dir(path)
    return get_dir_contains(path, '.svn')
end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
    isNeeded = false,
    text = "",
    textColor = 0,
    fillColor = 0
}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
    segment.isNeeded = get_svn_dir()
    if segment.isNeeded then
        -- if we're inside of svn repo then try to detect current branch
        local branch = get_svn_branch(git_dir)
        if branch then
            local svnStatus = get_svn_status()
            segment.text = " "..plc_git_branchSymbol.." "..branch.." "

            if svnStatus then
                segment.textColor = segmentColors.clean.text
                segment.fillColor = segmentColors.clean.fill
                segment.text = segment.text..""
                return
            end

            segment.textColor = segmentColors.dirty.text
            segment.fillColor = segmentColors.dirty.fill
            segment.text = segment.text.."± "
        end
    end
end 

---
-- Uses the segment properties to add a new segment to the prompt
---
local function addAddonSegment()
    init()
    if segment.isNeeded then 
        addSegment(segment.text, segment.textColor, segment.fillColor)
    end 
end 

-- Register this addon with Clink
clink.prompt.register_filter(addAddonSegment, 61)