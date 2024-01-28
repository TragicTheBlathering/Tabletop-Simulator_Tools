--******************************************************************************
--*** Variables needed throughout the entire obj Script (sudo global)***********
--******************************************************************************
local TagTarget = {'NameTag_Tags', 'NameTag_NameDesc', 'NameTag_GMNotes', 'NameTag_Edit', 'NameTag_ObjToggle', 'NameTag_ObjProp'} --NameTag_ObjProp
local ShowCast = true
local Wait_ids = {}
local hexC = {black  = '['..Color.black:toHex(false)..']',
              blue   = '['..Color.blue:toHex(false)..']',
              brown  = '['..Color.brown:toHex(false)..']',
              green  = '['..Color.green:toHex(false)..']',
              grey   = '['..Color.grey:toHex(false)..']',
              orange = '['..Color.orange:toHex(false)..']',
              pink   = '['..Color.pink:toHex(false)..']',
              purple = '['..Color.purple:toHex(false)..']',
              red    = '['..Color.red:toHex(false)..']',
              teal   = '['..Color.teal:toHex(false)..']',
              white  = '['..Color.white:toHex(false)..']',
              yellow = '['..Color.yellow:toHex(false)..']',
              close  = '[-]'}
local ButtonsCols = {}
local ButtonsData = {nameCol = 'Pink', nameName = 'Replace', tagAdd = 'Pink', tagName = 'Add', setAll = 'Red', editCol = 'Pink', editName='N'}
local AllObjectData = {error = false, objData = {}}
--******************************************************************************
--*** Main Function Cascade ****************************************************
--******************************************************************************
function b_func_ProcessNoteCards(obj, playercolor, alt_click)
    AllObjectData.error = false
    local notepadData = findNoteCard_Platforms()
    local valid = {}
    --print('------------------')
    if notepadData.found then
        printToAll(hexC.yellow..'-------------------------------------------------')
        printToAll(hexC.green..'Procssing : '..hexC.yellow..'Objects on Tool.')

        notepadData = processFound_NoteCards(notepadData)
        local formatedData = Process_NotepadData(notepadData)
        Edit_ObjectsOnTool(formatedData)

        print('\n----- RETURN')

    else
        AllObjectData.error = true
        printToAll(hexC.red..'-------------------------------------------------')
        printToAll(hexC.red..'Error : '..hexC.yellow..'Use only 1 copy of each platform type.')
        for k,v in pairs(notepadData.errorList) do
            printToAll(hexC.pink..'Object : '..hexC.orange..k..' : '..hexC.pink..'Copies : '..hexC.orange..v)
        end
        printToAll(hexC.red..'Fix : '..hexC.yellow..'Use the bag button to delete these platforms and try again')
        printToAll(hexC.red..'-------------------------------------------------')
    end
end

function Process_NotepadData(notepadData)
    --print('  *** Process_NotepadData() ***\n')
    --AllObjectData = cast(self, 'mainTool', Vector(18.8,5,18.8))
    --print(logString(notepadData, 'notepadData'))
    --print(logString(AllObjectData, 'AllObjectData'))

    local formatedData = {}
    for tag, data in pairs(notepadData) do
        if data then
            if 'NameTag_Tags' == tag then
                formatedData.TAGS = processData_TAGS(data.desc)
            elseif 'NameTag_NameDesc' == tag then

            elseif 'NameTag_GMNotes' == tag then

            elseif 'NameTag_ObjToggle' == tag then

            elseif 'NameTag_ObjProp' == tag then

            elseif 'NameTag_Edit' == tag then
            end
        end
    end

    --print(logString(d, '\n----- formatedData -----'))
    return formatedData
end

function processData_TAGS(data)
    local dataList = splitString(data)
    local tagList = {add = {}, remove = {}}

    for k,v in pairs(dataList) do
        if v:sub(1, 2) ~= '--' then                         -- ignore lines with -- at start
            if findInString(v, 'add:').found then           -- find lines with add: at start (not case sensitive)
                if string.lower(v:sub(1, 4)) == 'add:' then -- Make sure add key is 100% correct
                    local tag = v:sub(5)                    -- remove the start of line
                    tag = removeWhiteSpace(tag)             -- remove any white spaces
                    table.insert(tagList.add, tag)          -- Add line to tagList.add
                else
                    printToAll(hexC.red..'ERROR : '..hexC.white..'ADD Tags must only have \"add:\" at the start of the line')
                    AllObjectData.error = true
                end

            elseif findInString(v, 'remove:').found then -- repeate but for remove:
                if string.lower(v:sub(1, 7)) == 'remove:' then
                    local tag = v:sub(8)
                    tag = removeWhiteSpace(tag)
                    table.insert(tagList.remove, tag)
                else
                    printToAll(hexC.red..'ERROR : '..hexC.white..'REMOVE Tags must only have \"remove:\" at the start of the line')
                    AllObjectData.error = true
                end
            end
        end
    end
    table.sort(tagList.add)
    table.sort(tagList.remove)
    print(logString(tagList, '----- tagList ------'))
    return tagList
end

--[[
for k, str in pairs(desc) do
    if string.find(string.lower(str), 'add:', 1, true) then
        local line = str:sub(5) --str:gsub("%remove:", "")
        line = stringtools.removeWhiteSpace(line)
        table.insert(z.add, line)
    elseif string.find(string.lower(str), 'remove:', 1, true) then
        local line = str:sub(8) --str:gsub("%remove:", "")
        line = stringtools.removeWhiteSpace(line)
        table.insert(z.remove, line)
    end
end
--]]

--******************************************************************************
--*** Edit Objects *************************************************************
--******************************************************************************
function Edit_ObjectsOnTool(formatedData)
    print('\n----- Edit_ObjectsOnTool ------\n')
    local objData = cast(self, 'mainTool', Vector(18.8,5,18.8)) -- retutns {bags = {obj = data}, decks = {obj = data}, objs = {obj = data}}
    AllObjectData.objData = objData

    --print(logString(formatedData, '\n----- formatedData -----'))
    --log(formatedData)
    --print(logString(objData, '\n----- objData -----'))

    if not AllObjectData.error then
        --print('NO ERROR')
        if formatedData.TAGS then
            for o, data in pairs(objData.objs) do
                AllObjectData.objData.objs[o] = Set_Tags(data, formatedData.TAGS)
                --print(AllObjectData.objData.objs[obj].GUID)
            end

            for o, bagData in pairs(objData.bags) do
                --print(log(bagData.ContainedObjects))
                for k, data in pairs(bagData.ContainedObjects) do
                    --print(log(AllObjectData.objData.bags[o].ContainedObjects))
                    AllObjectData.objData.bags[o].ContainedObjects[k] = Set_Tags(data, formatedData.TAGS)
                    --AllObjectData.objData.bags[b][] = Set_Tags(data, formatedData.TAGS)
                end
            end
        end
    end


    if not AllObjectData.error then
        for _, type in pairs(AllObjectData.objData) do
            for obj, oData in pairs(type) do
                local pos = obj.getPosition()+Vector(0,3,0)
                local rot = obj.getRotation()
                local scale = Vector(oData.Transform.scaleX, oData.Transform.scaleY, oData.Transform.scaleZ)

                --print('----- objData.Tags - used in spawnObjctData() -----')
                --print(logString(AllObjectData.objData.objs[obj].Tags))

                destroyObject(obj)
                local newObj = spawnObjectData({data = oData, position=pos, rotation=rot, scale=scale, sound=true})
                --print(logString(newObj.getData().Tags, '\n----- getData.Tags on the newly Spawned Object -----'))
                --print('--------------------------------------------------')
            end
        end
    end

    --else
    --    print('****************************************')

    print('\n----- Edit_ObjectsOnTool ------')
end
--******************************************************************************
--*** Set objData Function  ****************************************************
--******************************************************************************
function Set_Tags(data, tags)
    print('\n  +++ SET TAGS +++')

    --local origTags = false ; if data.Tags then origTags = true end
    local origTags = data.Tags and true or false

    if ButtonsData.tagName == 'Remove'then
        print('REMOVE')

    elseif ButtonsData.tagName == 'Clear' then
        print('CLEAR')

    elseif ButtonsData.tagName == 'Replace'  then
        print('REPLACE')

    elseif ButtonsData.tagName == 'Add'  then
        print('ADD')
        if not origTags then
            data.Tags = {}
        end
        for k,tag in pairs(tags.add) do
            table.insert(data.Tags, tag)
        end
        table.sort(data.Tags)
    end

    --print(logString(data.Tags,'\n---------------data.Tags'))

    print('\n  +++ SET TAGS +++')
    return data
end
--[[
function Set_Tags(objData, tags)
    --print(logString(objData, 'objData'))
    --print(logString(tags, 'tags'))
    local spawn = false
    local origTags = objData.Tags
    objData.Tags = origTags and origTags or {} -- if not origTags then; objData.Tags = {}; end
    --print('??')
    if buttonsData.tagName == 'Remove' and origTags then
        for k, oTag in pairs(origTags) do
            for _, rTag in pairs(tags.remove) do
                if string.lower(oTag) == string.lower(rTag) then
                    --print(oTag..' : '..rTag)
                    origTags[k] = nil
                end
            end
        end
        --print('')
        local newTags = {}
        for k,v in pairs(origTags) do
            table.insert(newTags, v)
        end
        objData.Tags = newTags
        spawn = true

    elseif buttonsData.tagName == 'Clear' then
        objData.Tags = {}
        spawn = true

    elseif buttonsData.tagName == 'Replace'  then
        objData.Tags = {}
        for k,tag in pairs(tags.add) do
            table.insert(objData.Tags, tag)
        end
        spawn = true

    elseif buttonsData.tagName == 'Add'  then
        for k,tag in pairs(tags.add) do
            table.insert(objData.Tags, tag)
        end
        spawn = true
    end

    table.sort(objData.Tags)--print(tag)
    --print(logString(objData.Tags,'---------------------'))
    return spawn
end
--]]
--******************************************************************************
--*** Data Extraction **********************************************************
--******************************************************************************
function processFound_NoteCards(notepadData)
    -- Test if the buttons are green
    for tag, platform in pairs(notepadData.platforms) do
        local switch = false
        if ButtonsCols[tag] == 'Green' then switch = true end
        notepadData.platforms[tag] = {green = switch, obj = platform}
    end

    -- Do a cast on each platform accocisated with a green button.
    -- Find a NotePad.
    -- If one is found, then run the DataExtraction on that card and return.
    local data_NoteCards = {}
    for tag, platform in pairs(notepadData.platforms) do
        local obj = platform.obj
        data_NoteCards[tag] = cast(obj, 'noteCard')
    end

    -- Set all buttons that are green, which do not have a NotePad accociated with them to RED
    for tag ,switch in pairs(data_NoteCards) do
        if switch == false then
            --editButtonColours(tag) dose a Red -> Green and back switch. So to make everything RED make sure they are set to GREEN
            ButtonsCols[tag] = 'Green'
            editButtonColours(tag)
        end
    end

    -- Clear and Rebuild Buttons. For fucks sake... LEARRN XML you lazy cunt!
    self.clearButtons()
    MakeButtons()

    return data_NoteCards
end

function findNoteCard_Platforms() -- Seacrh Platforms for Tags used by mod and return
    local objList = {}
    local proceed = {found = true, errorList = {}, platforms = {}}

    for k,tag in pairs(TagTarget) do
        objList[tag] = getObjectsWithTag(tag)
        if objList[tag][1] then
            proceed.platforms[tag] = objList[tag][1]
        end
    end

    for k,v in pairs(objList) do
        --print(k..' :'..#v)
        if #v > 1 then
            proceed.found = false
            proceed.errorList[v[1].getName()] = #v
        end
    end
    return proceed
end

--------------------------------------------------------------------------------
--- Cast Code and Data Extraction ----------------------------------------------
function cast(target,switch, vec)
    vec = vec or Vector(2,2,2)
    local platform = {size=vec, posOffset=Vector(0, 0.7, 0)}
    local size = platform.size
    local zone = Physics.cast({ origin=target.getPosition() + platform.posOffset,
                                direction={0,1,0},
                                type=3,
                                max_distance=0,
                                size=size,
                                debug=ShowCast})
    return processCast(zone, switch)
end

function processCast(zone, switch)
    if switch == 'noteCard' then
        local z = {found = false, data = {}}
        for k,o in pairs(zone) do
            if o.hit_object.type == 'Notecard' then
                z.found = true
                z.data.name = o.hit_object.getName()
                z.data.desc = o.hit_object.getDescription()
                z.data.gmn = o.hit_object.getGMNotes()
                z.data.obj = o.hit_object
            end
        end
        if z.found then
            --print('FOUND')
            return z.data
        else
            --print('NO')
            return false
        end

    elseif switch == 'mainTool' then
        local data = {objs = {}, bags = {}, decks = {}}
        for k,o in pairs(zone) do
            local obj = o.hit_object
            if (obj ~= self) and (obj.type ~= 'Surface') then

                if obj.type == 'Bag' then
                    data.bags[obj] = obj.getData()
                    --table.insert(data.bags , obj.getData())
                elseif obj.type == 'Deck' then
                    data.decks[obj] = obj.getData()
                    --table.insert(data.decks , obj.getData())
                else
                    data.objs[obj] = obj.getData()
                    --table.insert(data.objs , obj.getData())
                end
            end
        end
        if tableSize(data.bags) == 0 and tableSize(data.decks) == 0 and tableSize(data.objs) == 0 then
            printToAll(hexC.red..'ERROR : '..hexC.white..'There are no objects on the tool!')
            AllObjectData.error = true
            return data
        else
            return data
        end
    end
end
--******************************************************************************
--*** TOOLS ********************************************************************
--******************************************************************************
--- Table Tools ----------------------------------------------------------------
function tableSize(t)
    local count = 0
    for key,value in pairs(t) do count = count + 1 end
    return count
end

function tableTest_identicalValues(t)
    --print(logString(t,'\nTable Test'))
    local first_value = nil
    for _, value in pairs(t) do
        if first_value == nil then
            first_value = value
        elseif value ~= first_value then
            --print('false')
            return false
        end
    end
    --print('true')
    return true
end
--------------------------------------------------------------------------------
--- String Tools ---------------------------------------------------------------
function removeWhiteSpace(s)
   return s:gsub("%s+", "")
end

function removeSubString(s,sub)
    return s:sub(#sub+1)
end

function findInString(line,key)
    local data = {}
    if string.find(string.lower(line), string.lower(key), 1, true) then
        data.sting = line
        data.found = true
    else
        data.sting = ''
        data.found = false
    end
    return data
end

function splitString(str, b1, b2)
    local z = {}
        if not str then
            printToAll('splitString(str, sep, b1, b2) : Must Provide a string (at least)', 'Red')
        else
            -- split at NEW LINE
            if not b1 and not b2 then
                for s in str:gmatch("[^\r\n]+") do
                    table.insert(z, s)
                end
            else
            -- split at SEPERATOR
                if b1 and not b2 then
                    if b1 == '' then b1 = ' ' end
                    for s in string.gmatch(str, "([^"..'%'..b1.."]+)") do
                        table.insert(z, s)
                    end
            -- split Between
                elseif b1 and b2 then
                    for s in string.gmatch(str, '%'..b1..'(.-)%'..b2) do
                        table.insert(z, s)
                    end
                end
            end
        end
    return z
end
--******************************************************************************
--*** Save / Onload ************************************************************
--******************************************************************************
function onSave()
    if tableSize(ButtonsCols) == 0 then saved_data = "" return saved_data
    else
        local data_to_save = { bCol=ButtonsCols, bData=ButtonsData }
        saved_data = JSON.encode(data_to_save)
        --saved_data = "" --Remove -- at start + save to clear save data
        return saved_data
    end
end

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        --Set up information off of loaded_data
        ButtonsCols = loaded_data.bCol
        ButtonsData = loaded_data.bData
    else
        --Set up information for if there is no saved saved data
        ButtonsCols = {}
        for k,v in pairs(TagTarget) do
            ButtonsCols[v] = 'Green'
        end
        ButtonsData = {nameCol = 'Pink', nameName = 'Replace', tagAdd = 'Pink', tagName = 'Add', setAll = 'Red', editCol = 'Pink', editName='N'}
    end
    if not self.getScale():equals(Vector(0.52, 0.79, 0.80)) then self.setScale(Vector(0.52, 0.79, 0.80)) end
    BuildHotKeys()
    MakeButtons()
end
--******************************************************************************
--*** Make Buttons *************************************************************
--******************************************************************************
function b_func_none()end
function MakeButtons(colour, tooltip)

-- Process Button --------------------------------------------------------------
    self.createButton({
        label='Process NoteCards',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_ProcessNoteCards", function_owner=self,
        position={0,0.6,14}, rotation={0,0,0}, height=650, width=3500,
        font_size=350, scale={1.5,1.5,1.5}--, color={0,0,0}, font_color={1,1,1}
    })

-- Main Switches ---------------------------------------------------------------
-- Name Description ------------------------------------------------------------
    self.createButton({
        label='Name / Desc',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_edit_NameDesc", function_owner=self,
        position={-5,1,11.3}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=ButtonsCols.NameTag_NameDesc, font_color={1,1,1}
    })
        self.createButton({
            label=ButtonsData.nameName,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_nameType", function_owner=self,
            position={-5,1,12.4}, rotation={0,0,0}, height=550, width=1600,
            font_size=250, scale={0.8,0.8,0.8}, color=ButtonsData.nameCol, font_color={1,1,1}
        })
-- GM Notes --------------------------------------------------------------------
    self.createButton({
        label='GM Notes',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_gmn", function_owner=self,
        position={0,1,11.3}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=ButtonsCols.NameTag_GMNotes, font_color={1,1,1}
    })
-- Tags ------------------------------------------------------------------------
    self.createButton({
        label='Tags',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_tags", function_owner=self,
        position={5,1,11.3}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=ButtonsCols.NameTag_Tags, font_color={1,1,1}
    })
        self.createButton({
            label=ButtonsData.tagName,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_tagType", function_owner=self,
            position={5,1,12.4}, rotation={0,0,0}, height=550, width=1600,
            font_size=250, scale={0.8,0.8,0.8}, color=ButtonsData.tagAdd, font_color={1,1,1}
        })
-- Edit Values -----------------------------------------------------------------
    self.createButton({
        label='Edit',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_edit", function_owner=self,
        position={5,1,10}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=ButtonsCols.NameTag_Edit, font_color={1,1,1}
    })
        self.createButton({
            label=ButtonsData.editName,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_editType", function_owner=self,
            position={7.3,1,10}, rotation={0,0,0}, height=550, width=750,
            font_size=250, scale={0.7,0.7,0.7}, color=ButtonsData.editCol, font_color={1,1,1}
        })
-- Object Toggles --------------------------------------------------------------
    self.createButton({
        label='Toggles',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_toggle", function_owner=self,
        position={0,1,10}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=ButtonsCols.NameTag_ObjToggle, font_color={1,1,1}
    })
-- Object Properties -----------------------------------------------------------
    self.createButton({
        label='Properties',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_prop", function_owner=self,
        position={-5,1,10}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=ButtonsCols.NameTag_ObjProp, font_color={1,1,1}
    })
--------------------------------------------------------------------------------
-- Spawn Bags ------------------------------------------------------------------
    self.createButton({
        label='Spawn Bags', tooltip="Spawns a Bags",
        click_function="b_func_SpawnBags", function_owner=self,
        position={6.5,0.6,-9.5}, rotation={0,0,0}, height=550, width=2000,
        font_size=250, scale={1.2,1.2,1.2}--, color={0,0,0}, font_color={1,1,1}
    })
--[[
    self.createButton({
        label='Print Results', tooltip=printSwitch.tooltip,
        click_function="b_func_PrintSwitch", function_owner=self,
        position={-6.5,0.6,-9.5}, rotation={0,0,0}, height=550, width=2000,
        color=printSwitch.colour, font_color='White',
        font_size=250, scale={1.2,1.2,1.2}--, color={0,0,0}, font_color={1,1,1}
    })--]]
end
--------------------------------------------------------------------------------
-- Edit Main Button Colours ----------------------------------------------------
function editButtonColours(buttonName)
    if buttonName == true then
        if ButtonsData.setAll == 'Green' then
            for k,v in pairs(ButtonsCols) do
                ButtonsCols[k] = 'Red'
            end
            ButtonsData.setAll = 'Red'
        elseif ButtonsData.setAll == 'Red' then
            for k,v in pairs(ButtonsCols) do
                ButtonsCols[k] = 'Green'
            end
            ButtonsData.setAll = 'Green'
        end
    else
        if ButtonsCols[buttonName] == 'Green' then ButtonsCols[buttonName] = 'Red' else ButtonsCols[buttonName] = 'Green' end
        if tableTest_identicalValues(ButtonsCols) then
            if ButtonsCols.NameTag_Tags == 'Green' then
                ButtonsData.setAll = 'Green'
            else
                ButtonsData.setAll = 'Red'
            end
        end

    end
    self.clearButtons()
    MakeButtons()
end

function b_func_editType (obj, playercolor, alt_click)
    if not alt_click then
        if ButtonsData.editCol == 'Pink' then
            ButtonsData.editCol = 'Orange'
            ButtonsData.editName = 'D'

        elseif ButtonsData.editCol == 'Orange' then
            ButtonsData.editCol = 'Blue'
            ButtonsData.editName = 'A'

        elseif ButtonsData.editCol == 'Blue' then
            ButtonsData.editCol = 'Teal'
            ButtonsData.editName = 'N+D'

        elseif ButtonsData.editCol == 'Teal' then
            ButtonsData.editCol = 'Purple'
            ButtonsData.editName = 'G'

        elseif ButtonsData.editCol == 'Purple' then
            ButtonsData.editCol = 'Pink'
            ButtonsData.editName = 'N'

        end
    else
        --print('!!!')
    end
    self.clearButtons()
    MakeButtons()
end
-- Edit NAME OPTIONS -----------------------------------------------------------
function b_func_nameType(obj, playercolor, alt_click)
    --local ButtonsData = {nameCol = 'Pink', nameName = 'Replace', tagAdd = 'Pink', tagName = 'Add', setAll = 'Red'}
    if not alt_click then
        if ButtonsData.nameCol == 'Pink' then
            ButtonsData.nameCol = 'Orange'
            ButtonsData.nameName = 'Prefix'

        elseif ButtonsData.nameCol == 'Orange' then
            ButtonsData.nameCol = 'Blue'
            ButtonsData.nameName = 'Suffix'

        elseif ButtonsData.nameCol == 'Blue' then
            ButtonsData.nameCol = 'Pink'
            ButtonsData.nameName = 'Replace'
        end
    else
        --print('!!!')
    end
    self.clearButtons()
    MakeButtons()
end

-- TAG OPTIONS -----------------------------------------------------------------
function b_func_tagType(obj, playercolor, alt_click)
    --local ButtonsData = {tagAdd = 'Orange', tagName = 'Add', setAll = 'false'}
    if not alt_click then
        if ButtonsData.tagAdd == 'Pink' then
            ButtonsData.tagAdd = 'Orange'
            ButtonsData.tagName = 'Replace'

        elseif ButtonsData.tagAdd == 'Orange' then
            ButtonsData.tagAdd = 'Blue'
            ButtonsData.tagName = 'Remove'

        elseif ButtonsData.tagAdd == 'Blue' then
            ButtonsData.tagAdd = 'Purple'
            ButtonsData.tagName = 'Clear'

        elseif ButtonsData.tagAdd == 'Purple' then
            ButtonsData.tagAdd = 'Pink'
            ButtonsData.tagName = 'Add'
        end
    else
        --print('!!!') Clear
    end
    self.clearButtons()
    MakeButtons()
end
--------------------------------------------------------------------------------
-- Actual Button Functions to Edit the Colours  --------------------------------
function b_func_edit_NameDesc(obj, playercolor, alt_click)
    if not alt_click then
        editButtonColours('NameTag_NameDesc')
    else
        editButtonColours(true)
    end
end

function b_func_gmn(obj, playercolor, alt_click)
    if not alt_click then
        editButtonColours('NameTag_GMNotes')
    else
        editButtonColours(true)
    end
end

function b_func_tags(obj, playercolor, alt_click)
    if not alt_click then
        editButtonColours('NameTag_Tags')
    else
        editButtonColours(true)
    end
end

function b_func_edit(obj, playercolor, alt_click)
    if not alt_click then
        editButtonColours('NameTag_Edit')
    else
        editButtonColours(true)
    end
end

function b_func_toggle(obj, playercolor, alt_click)
    if not alt_click then
        editButtonColours('NameTag_ObjToggle')
    else
        editButtonColours(true)
    end
end

function b_func_prop(obj, playercolor, alt_click)
    if not alt_click then
        editButtonColours('NameTag_ObjProp')
    else
        editButtonColours(true)
    end
end

--******************************************************************************
--*** Hot Key Stuff ************************************************************
--******************************************************************************
function BuildHotKeys()
    addHotkey("Tags_Print",hot_PrintTags , false)
    addHotkey("Tags_CLEAR",hot_ClearTags , false)
    addHotkey("Toggle ToolTip",hot_ToggleToolTips , false)
    --addHotkey("Tags_ADD",hot_AddTags , false)
    --addHotkey("Tags_REPLACE",hot_ReplaceTags , false)
    --addHotkey("Tags_REMOVE",hot_RemoveTags , false)
end

function hot_ClearTags(playerColor, object, pointerPosition, isKeyUp)
    if object then
        local name = object.getName()
        if name == '' then name = tostring(object) end
        printToAll('\n'..name, 'Orange')
        printToAll('   Clearing All Tags', 'Red')
        object.setTags({})
    else
        printToAll('ERROR : There is no Object Under the Cursor', 'Red')
    end
end

function hot_PrintTags(playerColor, object, pointerPosition, isKeyUp)
    if object then
        local objString = tostring(object)
        local nameString = object.getName()
        local tags = object.getData().Tags

        if nameString == '' then
            nameString = '<No Name>'
        end

        printToAll('\n'..objString,'Orange')
        printToAll(' Object Name : '..nameString, 'Yellow')
        if tags then
            table.sort(tags)
            for k,v in ipairs(tags) do
                printToAll(' '..k..' : '..v)
            end
        else
            printToAll(' ERROR : There are no Tags on the object', 'Red')
        end
    end
end

function hot_ToggleToolTips(playerColor, object, pointerPosition, isKeyUp)
    if object then
        if object.tooltip == true then
            object.tooltip = false
        else
            object.tooltip = true
        end
    end
end