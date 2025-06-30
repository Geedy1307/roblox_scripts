local TestTable = {Vector3.new(0, 5, 999), 'Shit', 'Damn', Instance.new('Fire', workspace)};

local Apostrophe = string.char(39)
local TableToString = function(tbl, tablename, setclipboard2, TypeSettings1)
    local TypeSettings = TypeSettings1 or {['CFrame'] = 'new', ['Vector3'] = 'new', ['Vector2'] = 'new', ['UDim2'] = 'new', ['Color3'] = 'fromRGB', ['Instance'] = 'new'}
    local ValidTypes = {'CFrame', 'Vector3', 'Vector2', 'UDim2', 'Color3', 'Instance'} -- Idk them all so help!!!
    local GetType = function(userdata, typesettings)
        if userdata and typeof(userdata) then
            local userdataStr = typeof(userdata):gsub('Part', 'Instance')
            if table.find(ValidTypes, userdataStr) and typesettings and type(typesettings) == 'table' then
                local Formatted;
                if typeof(userdata) == 'Instance' or typeof(userdata) == 'Part' then
                    if userdata['Parent'] then
                        Formatted = 'Instance'..'.'..typesettings[userdataStr]..'('..Apostrophe..tostring(userdata)..Apostrophe..', '..userdata.Parent.Name..' --[[(not exact parent)]])'
                    else
                        Formatted = 'Instance'..'.'..typesettings[userdataStr]..'('..Apostrophe..tostring(userdata)..Apostrophe..')'
                    end
                else
                    Formatted = userdataStr..'.'..typesettings[userdataStr]..'('..tostring(userdata)..')'
                end
                return Formatted
            else
                return userdata
            end
        end
    end
    
    local String;
    if tablename and type(tablename) == 'string' and tablename:len() > 0 then -- Table has to be a string, you can only copy string data to the clipboard until it's parsed;
        String = 'local '..tablename..' = {'
    else
        String = 'local NewTable = {'
    end
    if tbl and type(tbl) == 'table' then
        for _, v in next, tbl do
            if _ ~= #tbl then
                if type(v) ~= 'string' then
                    String = String..GetType(v, TypeSettings)..', '
                else
                    String = String..Apostrophe..GetType(v, TypeSettings)..Apostrophe..', '
                end
            else
                if type(v) ~= 'string' then
                    String = String..GetType(v, TypeSettings)..'}'
                else
                    String = String..Apostrophe..GetType(v, TypeSettings)..Apostrophe..'}'
                end
            end
        end
        if setclipboard2 then
            setclipboard(String)
        elseif not setclipboard2 then
            return String
        end
    end
end

TableToString(TestTable, 'TestTable', true, {['CFrame'] = 'new', ['Vector3'] = 'new', ['Vector2'] = 'new', ['UDim2'] = 'new', ['Color3'] = 'fromRGB', ['Instance'] = 'new'})