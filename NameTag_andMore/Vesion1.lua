--******************************************************************************
--*** Variables needed throughout the entire obj Script (sudo global)***********
--******************************************************************************
--local printSwitch = {obj = true, cards = false, colour = 'Blue', tooltip=': Result Printout :\nDECKS : DISABLED\nOBJECTS : ENABLED', proccessIdentSwitch = 'Red'}
local tagTarget = {'NameTag_Tags', 'NameTag_NameDesc', 'NameTag_GMNotes', 'NameTag_Edit', 'NameTag_ObjToggle', 'NameTag_ObjProp'} --NameTag_ObjProp
local ShowCast = false--true
local wait_ids = {}
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
local buttonsCols = {}
local buttonsData = {nameCol = 'Pink', nameName = 'Replace', tagAdd = 'Pink', tagName = 'Add', setAll = 'Red', editCol = 'Pink', editName='N'}
local tool = {}

--******************************************************************************
--*** Save / Onload ************************************************************
--******************************************************************************
function onSave()
    if tableSize(buttonsCols) == 0 then saved_data = "" return saved_data
    else
        local data_to_save = { bCol=buttonsCols, bData=buttonsData }
        saved_data = JSON.encode(data_to_save)
        --saved_data = "" --Remove -- at start + save to clear save data
        return saved_data
    end
end

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        --Set up information off of loaded_data
        buttonsCols = loaded_data.bCol
        buttonsData = loaded_data.bData
    else
        --Set up information for if there is no saved saved data
        buttonsCols = {}
        for k,v in pairs(tagTarget) do
            buttonsCols[v] = 'Green'
        end
        buttonsData = {nameCol = 'Pink', nameName = 'Replace', tagAdd = 'Pink', tagName = 'Add', setAll = 'Red', editCol = 'Pink', editName='N'}
    end
    if not self.getScale():equals(Vector(0.52, 0.79, 0.80)) then self.setScale(Vector(0.52, 0.79, 0.80)) end
    MakeButtons()
end

--******************************************************************************
--*** Main Function Cascade ****************************************************
--******************************************************************************
function b_func_ProcessNoteCards(obj, playercolor, alt_click)
            local function error_toManyPlatforms(errorList)
                for k,v in pairs(errorList) do
                    print()
                    printToAll(hexC.pink..'Object : '..hexC.orange..k..hexC.pink..'\n - Copies : '..hexC.orange..v)
                end
                printToAll(hexC.green..' - Fix : Use the bag button to delete these platforms and try again')
            end

    local notepadData = findNoteCardData()
    local valid = {}
    --print('------------------')
    if notepadData.proceed.found then
        notepadData = processNoteCards(notepadData)
        for k,v in pairs(notepadData) do
            if v ~= false then
                valid[k] = v
            end
        end
        --print(logString(valid, '\n *** valid ***'))
        StartProcessingDataOnNoteCards(valid)
    else
        printToAll(hexC.red..'Error : '..hexC.yellow..'You have more than one NotePad Stand of the same type in scene')
        error_toManyPlatforms(notepadData.proceed.errorList)
    end
end
--------------------------------------------------------------------------------
-- Process Data from found NoteCards -------------------------------------------
function StartProcessingDataOnNoteCards(validData)
    print('  ********************************************')
    print('  *** '..hexC.green..'START'..hexC.close..' Processing Data On Note Cards ***')
    --tagTarget = {'NameTag_Tags', 'NameTag_NameDesc', 'NameTag_GMNotes', 'NameTag_ObjToggle', 'NameTag_ObjProp', 'NameTag_Edit'}
    local cardData = {}
          cardData.objects = cast(self, 'mainTool', Vector(18.8,5,18.8))
          cardData.data = {}

    for k,v in pairs(validData) do
        if 'NameTag_Tags' == k then
            cardData.data.tags = process_TAGS(v.desc)
        elseif 'NameTag_NameDesc' == k then
            cardData.data.name = v.name
            cardData.data.desc = v.desc
        elseif 'NameTag_GMNotes' == k then
            cardData.data.gmn = v.desc
        elseif 'NameTag_ObjToggle' == k then
            cardData.data.togs = {}
            cardData.data.togs.names = {'Locked', 'DragSelectable','Snap','Grid','Autoraise','Sticky','Hands','HideWhenFaceDown','FogOfWarRevealer','IgnoreFoW','MeasureMovment','Tooltip','GridProjection'}--, ''}
            cardData.data.togs.switch = process_TOGGLES(v.obj, cardData.data.togs.names)
        elseif 'NameTag_ObjProp' == k then
            cardData.data.properties = process_PROPS(v.desc)
        elseif 'NameTag_Edit' == k then
            cardData.data.edit = {}
            cardData.data.edit.find = v.name
            cardData.data.edit.replace = v.desc
        end
    end
    --print(logString(cardData, '\n *** Card Data ***'))
    ProcessToolContent(cardData)
end
--******************************************************************************
--*** Edit Objects  ************************************************************
--******************************************************************************

function spawnEditedObject(cardData)

    for k, objData in pairs(cardData.objects.objs) do
        local obj = getObjectFromGUID(objData.GUID)
        local objD = obj.getData()
        print(logString(objD, '--------------------------------------'))
        local pos = obj.getPosition()+Vector(0,3,0)
        local rot = obj.getRotation()
        scale = Vector(objData.Transform.scaleX, objData.Transform.scaleY, objData.Transform.scaleZ)
        destroyObject(obj)
        spawnObjectData({data = objData, position=pos, rotation=rot, scale=scale, sound=true})
    end

    for k, objData in pairs(cardData.objects.bags) do
        local obj = getObjectFromGUID(objData.GUID)
        local pos = obj.getPosition()+Vector(0,3,0)
        local rot = obj.getRotation()
        local scale = obj.getScale()
        destroyObject(obj)
        spawnObjectData({data = objData, position=pos, rotation=rot, scale=scale, sound=true})
    end

    for k, objData in pairs(cardData.objects.decks) do
        local obj = getObjectFromGUID(objData.GUID)
        local pos = obj.getPosition()+Vector(0,3,0)
        local rot = obj.getRotation()
        local scale = obj.getScale()
        destroyObject(obj)
        spawnObjectData({data = objData, position=pos, rotation=rot, scale=scale, sound=true})
    end
    print('  *** '..hexC.red..'END'..hexC.close..'     Processing Data On Note Cards ***')
    print('  ********************************************')
end

function ProcessToolContent(cardData)
    local spawn = false

    for k, obj in pairs(cardData.objects.objs) do
        spawn = editObjects(obj, cardData)
    end

    for _, bag in pairs(cardData.objects.bags) do
        for _, obj in pairs(bag.ContainedObjects) do
            if obj.Name == 'Deck' then
                spawn = editObjects(obj, cardData)
                for _, card in pairs(obj.ContainedObjects) do
                    spawn = editObjects(card, cardData)
                end
            else
                spawn = editObjects(obj, cardData)
            end
        end
    end

    for _, deck in pairs(cardData.objects.decks) do
        spawn = editObjects(deck, cardData)
        for _, obj in pairs(deck.ContainedObjects) do
            for k, objData in pairs(obj) do
                spawn = editObjects(obj, cardData)
            end
        end
    end

    if spawn then spawnEditedObject(cardData) end
end

function editObjects(obj, cardData)
    local spawn = false
        if cardData.data.togs then
            spawn = Edit_setToggles(obj,cardData.data.togs)
        end

        if cardData.data.tags then
            spawn = Edit_setTags(obj,cardData.data.tags)
        end

        if cardData.data.name then
            spawn = Edit_setNames(obj,cardData.data.name)
        end

        if cardData.data.desc then
            if cardData.data.desc ~= '' then
                spawn = Edit_setDesc(obj,cardData.data.desc)
            end
        end

        if cardData.data.gmn then
            if cardData.data.gmn ~= '' then
                spawn = Edit_setGMNotes(obj,cardData.data.gmn)
            end
        end

        if cardData.data.edit then
            if cardData.data.edit ~= nil then
                spawn = Edit_searchReplace(obj,cardData.data.edit)
            end
        end

        if cardData.data.properties then
            if cardData.data.properties ~= nil then
                --spawn = Edit_changeProperties(obj,cardData.data.properties)
                --print(cardData.objects.objs[1].Transform.scaleX)
                spawn = Edit_changeProperties(obj,cardData)
                --print(cardData.objects.objs[1].Transform.scaleX)
            end
        end

    return spawn
end

--------------------------------------------------------------------------------
-- Change Object Properties ----------------------------------------------------
function Edit_changeProperties(objData, cardData)
    local prop = cardData.data.properties
    local objList = cardData.objects.objs
    print('EDIT PROPERTIES\n')

    print(logString(prop))
    print('\n')
    for _, t in ipairs(prop) do
        for key,data in pairs(t) do
            --print(data)
            if key == 'scale' then
                for k,v in pairs(objList) do
                    objList[k].Transform.scaleX = data.x
                    objList[k].Transform.scaleY = data.y
                    objList[k].Transform.scaleZ = data.z
                end
                spawn = true
            else
                local set = convertString(data)
                local path = search_table(objList,key)
                modifyValueViaPath(objList, path, set)
                spawn = true
            end
        end
    end
    return spawn
end

function convertString(str)
    local num = tonumber(str)
    if num then
        --print("The string is a valid representation of a number: " .. num)
        return num
    elseif str == "true" then
        --print("The string is a representation of the boolean value true")
        return true
    elseif str == "false" then
        --print("The string is a representation of the boolean value false")
        return false
    else
        --print("The string is not a valid representation of a number or boolean, it's a string of letters: " .. str)
        return str
    end
end

function modifyValueViaPath(tbl, path, newV)
    if path then
      local value = tbl
      for i, k in ipairs(path) do
        if i == #path then
          value[k] = newV--..  -- new value
        else
          value = value[k]
        end
      end
    end
end

function search_table(tbl, key, path)
  path = path or {}
  for k, v in pairs(tbl) do
    local current_path = {table.unpack(path)}
    table.insert(current_path, k)
    if string.lower(k) == string.lower(key) then
      return current_path
    end
    if type(v) == "table" then
      local result_path = search_table(v, key, current_path)
      if result_path then return result_path end
    end
  end
  return nil
end
--------------------------------------------------------------------------------
-- Search for text and Replace it ----------------------------------------------
function Edit_searchReplace(objData, edit)
    local spawn = false
    local find = string.lower(edit.find:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", function(c) return "%" .. c end)) -- convert string escaping all special charicters (if any)
    local replace = string.lower(edit.replace)

    for k, orig in pairs(objData) do
        if k == 'Nickname' and (buttonsData.editName == 'N' or buttonsData.editName == 'A' or buttonsData.editName == 'N+D') then
            --local result = string.gsub(string.lower(orig), find, replace)
            objData[k] = string.gsub(string.lower(orig), find, replace)
            spawn = true
        end

        if k == 'Description' and (buttonsData.editName == 'D' or buttonsData.editName == 'A' or buttonsData.editName == 'N+D') then
            objData[k] = string.gsub(string.lower(orig), find, replace)
            spawn = true
        end

        if k == 'GMNotes' and (buttonsData.editName == 'G' or buttonsData.editName == 'A') then
            objData[k] = string.gsub(string.lower(orig), find, replace)
            spawn = true
        end
    end

    return spawn
end
--------------------------------------------------------------------------------
-- Set GMNotes -----------------------------------------------------------------
function Edit_setGMNotes(objData, gmn)
    local spawn = false
        for k,v in pairs(objData) do
            if k == 'GMNotes' then
                objData[k] = gmn
                spawn = true
            end
        end
    return spawn
end
--------------------------------------------------------------------------------
-- Set Description -------------------------------------------------------------
function Edit_setDesc (objData, desc)
    local spawn = false
        for k,v in pairs(objData) do
            if k == 'Description' then
                objData[k] = desc
                spawn = true
            end
        end
    return spawn
end

--------------------------------------------------------------------------------
-- Set Names -------------------------------------------------------------------
--buttonsData nameCol = 'Pink', nameName = 'Replace'
function Edit_setNames(objData, name)
    local spawn = false
        for k,v in pairs(objData) do
            if k == 'Nickname' then
                if buttonsData.nameName == 'Replace' then
                    objData[k] = name
                    spawn = true
                elseif buttonsData.nameName == 'Prefix' then
                    objData[k] = name..v
                    spawn = true
                elseif buttonsData.nameName == 'Suffix' then
                    objData[k] = v..name
                    spawn = true
                end
            end
        end
    return spawn
end
--------------------------------------------------------------------------------
-- Edit Toggles ----------------------------------------------------------------
function Edit_setToggles(objData, togs)
    local spawn = false
    for k,v in pairs(objData) do
        for key, toggle in pairs(togs.switch) do
            if k == key then
                --print(key..' : '..tostring(toggle))
                objData[key] = toggle
                spawn = true
            end
        end
    end
    return spawn
end
--------------------------------------------------------------------------------
-- Edit Tags -------------------------------------------------------------------
function Edit_setTags(objData, tags)
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

--******************************************************************************
--*** Data Extraction **********************************************************
--******************************************************************************
function findNoteCardData()
    local z = {}
        --local objList = getObjectsWithAnyTags(tagTarget) do
        local objList = {}
        for _, v in ipairs(tagTarget) do
          objList[v] = {}
        end

        for k,t in pairs(tagTarget) do
            objList[t] = getObjectsWithTag(t)
        end

        --print(logString(objList))

        local proceed = {found = true, errorList = {}}
        for k,v in pairs(objList) do
            --print(k..' :'..#v)
            if #v > 1 then
                proceed.found = false
                proceed.errorList[v[1].getName()] = #v
            end
        end
        z.proceed = proceed
        --print(logString(z))
    return z
end


function processNoteCards(notepadData)
    --print('  *** Process all NoteCards ***\n')
    local platforms = {}
    for k,v in pairs(buttonsCols) do
        local switch = false
        if v == 'Green' then switch = true end
        platforms[getObjectsWithTag(k)[1]] = {green = switch, tag = k}
    end

    local notecardData = {}
    for obj, data in pairs(platforms) do
        --print(obj.getName())
        if data.green then
            notecardData[data.tag] = cast(obj, 'noteCard')
        end
    end
    return notecardData
end

--------------------------------------------------------------------------------
-- Find Data from NoteCards ----------------------------------------------------
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
        local Bags = {}
        local Objs = {}
        local Decks = {}
        local z = {found = false, data = {}}
        for k,o in pairs(zone) do
            if (o.hit_object ~= self) and (o.hit_object.type ~= 'Surface') then
                z.found = true
                if o.hit_object.type == 'Bag' then
                    table.insert(Bags , o.hit_object.getData())

                elseif o.hit_object.type == 'Deck' then
                    table.insert(Decks , o.hit_object.getData())

                else
                    table.insert(Objs , o.hit_object.getData())
                end
            end
        end

        if z.found then
            z.data.bags = Bags
            z.data.decks = Decks
            z.data.objs = Objs
            return z.data
        else
            return false
        end
    end
end
--******************************************************************************
--*** Process All Found Notecards **********************************************
--******************************************************************************
function process_PROPS(data)
    local dataList = {}
        --print(logString(dataList))
        for k,v in pairs(splitString(data)) do
            local extracted = splitString(v,':')
            --print(logString(tmp))
            --print()
            if string.lower(extracted[1]) == 'scale' then
                --print(extracted[1]..' : '..extracted[2])
                local tbl = {}
                tbl[string.lower(extracted[1])] = findVectorFrom_string(extracted[2])
                table.insert(dataList, tbl)
            else
                local tbl = {}
                tbl[string.lower(extracted[1])] = extracted[2]
                table.insert(dataList, tbl)
            end
        end
    --print(logString(dataList))
    return dataList
end

function process_TAGS(data)
    local dataList = splitString(data)
    local tagList = {add = {}, remove = {}}
    for k,v in pairs(dataList) do
        if v:sub(1, 2) ~= '--' then
            if findInString(v, 'add:').found then
                local tag = removeSubString_TAG(v,'add:')
                table.insert(tagList.add, tag)
            elseif findInString(v, 'remove:').found then
                local tag = removeSubString_TAG(v,'remove:')
                table.insert(tagList.remove, tag)
            end
        end
    end
    table.sort(tagList.add)
    table.sort(tagList.remove)
    return tagList
end

function process_TOGGLES(obj, keys)
    local z = {}
    local objData = obj.getData()
        for k, v in pairs(objData) do
            for _, key in pairs(keys) do
                if k == key then
                    --print(k..' : '..tostring(v))
                    z[k] = v
                end
            end
        end
        --print(logString(objData, 'objData')
    return z
end
--------------------------------------------------------------------------------
-- Spawn Bags on Tool ----------------------------------------------------------
function b_func_SpawnBags(obj, playercolor, alt_click)
    if not alt_click then
        tool.CountClicks(self,spawnBags, 0.4)
    else
        spawnBags(20)
    end
end

function spawnBags(clickCount)
    if clickCount > 20 then clickCount = 20 end
    local bagCount = 'Bag'; if clickCount > 1 then bagCount = 'Bags' end
    printToAll('\nSpawning '..clickCount..' '..bagCount, 'Orange')

    local OffSet = Vector(-7.5,2,5.5)
    local horizontal_spill = 0
    for i=1, clickCount, 1 do
        horizontal_spill = horizontal_spill + 1
        OffSet:sub(Vector(-3,0,0))
        if horizontal_spill > 4 then
            OffSet:sub(Vector(12,0,2.75))
            horizontal_spill = 1
        end

        local spawnedBag = spawnObject({
                type = 'Bag',
                position = self.getPosition()+OffSet,
                scale = {1, 1, 1},
                sound = true,
            })
        spawnedBag.setName('Edit Tags Bag '..i)
        spawnedBag.setDescription('Place Objects, Bags or Decks in this bag to edit the tags based on the Description of the SET TAGES TOOL')
    end
end

--******************************************************************************
--*** Tools ********************************************************************
--******************************************************************************

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

function tableSize(t)
    local count = 0
    for key,value in pairs(t) do count = count + 1 end
    return count
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

function findVectorFrom_string(s) --:sub(2, -2)
    if s:sub(1, 1) ~= '{' then
        local vec = splitString(s, ',')
        for k,v in ipairs(vec) do
            vec[k] = v:gsub("%s+", "") -- remove any whote spaces in number
        end
        return Vector(vec[1], vec[2], vec[3])
    else
        local vec = splitString(s:sub(2, -2), ',')
        for k,v in ipairs(vec) do
            vec[k] = v:gsub("%s+", "") -- remove any whote spaces in number
        end
        return Vector(vec[1], vec[2], vec[3])
    end
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

function removeSubString_TAG(s,sub)
    return s:sub(#sub+1)
end

--[[
print('ORIG : '..str)
function removeSubString(s,sub,nocase)
    nocase = nocase or false
    if nocase then
        s = string.lower(s)
        sub = string.lower(sub)
    end

    return s:gsub(sub,"")
end
--]]
--------------------------------------------------------------------------------
--- Tools --- ------------------------------------------------------------------
function tool.CountClicks(obj,func,delay)
    local delay = delay or 0.8 -- better way of setting default parameters
    wait_ids[obj] = wait_ids[obj] or { -- just to be sure there's no attempt to index a nil value later we set an empty table first.
      count = 0, -- We set the count to 0 here when the table is made
    }

    function delayCall()
        func(wait_ids[obj].count)
        wait_ids[obj].waitID = nil -- remove the wait id when the function is called
        wait_ids[obj].count = 0  -- We set the count to 0 here when the wait has ended due to timeout
    end

    if wait_ids[obj].waitID then Wait.stop(wait_ids[obj].waitID); wait_ids[obj].waitID = nil end -- end the previous wait if it exists
    wait_ids[obj].waitID = Wait.time(delayCall, delay) -- make a new wait, but with _no_ count

    wait_ids[obj].count = wait_ids[obj].count + 1 -- finally increment the click amount.
end
--------------------------------------------------------------------------------
-- Make Buttons ----= ----------------------------------------------------------
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
        font_size=250, scale={1,1,1}, color=buttonsCols.NameTag_NameDesc, font_color={1,1,1}
    })
        self.createButton({
            label=buttonsData.nameName,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_nameType", function_owner=self,
            position={-5,1,12.4}, rotation={0,0,0}, height=550, width=1600,
            font_size=250, scale={0.8,0.8,0.8}, color=buttonsData.nameCol, font_color={1,1,1}
        })
-- GM Notes --------------------------------------------------------------------
    self.createButton({
        label='GM Notes',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_gmn", function_owner=self,
        position={0,1,11.3}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=buttonsCols.NameTag_GMNotes, font_color={1,1,1}
    })
-- Tags ------------------------------------------------------------------------
    self.createButton({
        label='Tags',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_tags", function_owner=self,
        position={5,1,11.3}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=buttonsCols.NameTag_Tags, font_color={1,1,1}
    })
        self.createButton({
            label=buttonsData.tagName,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_tagType", function_owner=self,
            position={5,1,12.4}, rotation={0,0,0}, height=550, width=1600,
            font_size=250, scale={0.8,0.8,0.8}, color=buttonsData.tagAdd, font_color={1,1,1}
        })
-- Edit Values -----------------------------------------------------------------
    self.createButton({
        label='Edit',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_edit", function_owner=self,
        position={5,1,10}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=buttonsCols.NameTag_Edit, font_color={1,1,1}
    })
        self.createButton({
            label=buttonsData.editName,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_editType", function_owner=self,
            position={7.3,1,10}, rotation={0,0,0}, height=550, width=750,
            font_size=250, scale={0.7,0.7,0.7}, color=buttonsData.editCol, font_color={1,1,1}
        })
-- Object Toggles --------------------------------------------------------------
    self.createButton({
        label='Toggles',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_toggle", function_owner=self,
        position={0,1,10}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=buttonsCols.NameTag_ObjToggle, font_color={1,1,1}
    })
-- Object Properties -----------------------------------------------------------
    self.createButton({
        label='Properties',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_prop", function_owner=self,
        position={-5,1,10}, rotation={0,0,0}, height=550, width=1600,
        font_size=250, scale={1,1,1}, color=buttonsCols.NameTag_ObjProp, font_color={1,1,1}
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
        if buttonsData.setAll == 'Green' then
            for k,v in pairs(buttonsCols) do
                buttonsCols[k] = 'Red'
            end
            buttonsData.setAll = 'Red'
        elseif buttonsData.setAll == 'Red' then
            for k,v in pairs(buttonsCols) do
                buttonsCols[k] = 'Green'
            end
            buttonsData.setAll = 'Green'
        end
    else
        if buttonsCols[buttonName] == 'Green' then buttonsCols[buttonName] = 'Red' else buttonsCols[buttonName] = 'Green' end
        if tableTest_identicalValues(buttonsCols) then
            if buttonsCols.NameTag_Tags == 'Green' then
                buttonsData.setAll = 'Green'
            else
                buttonsData.setAll = 'Red'
            end
        end

    end
    self.clearButtons()
    MakeButtons()
end

function b_func_editType (obj, playercolor, alt_click)
    if not alt_click then
        if buttonsData.editCol == 'Pink' then
            buttonsData.editCol = 'Orange'
            buttonsData.editName = 'D'

        elseif buttonsData.editCol == 'Orange' then
            buttonsData.editCol = 'Blue'
            buttonsData.editName = 'A'

        elseif buttonsData.editCol == 'Blue' then
            buttonsData.editCol = 'Teal'
            buttonsData.editName = 'N+D'

        elseif buttonsData.editCol == 'Teal' then
            buttonsData.editCol = 'Purple'
            buttonsData.editName = 'G'

        elseif buttonsData.editCol == 'Purple' then
            buttonsData.editCol = 'Pink'
            buttonsData.editName = 'N'

        end
    else
        --print('!!!')
    end
    self.clearButtons()
    MakeButtons()
end
-- Edit NAME OPTIONS -----------------------------------------------------------
function b_func_nameType(obj, playercolor, alt_click)
    --local buttonsData = {nameCol = 'Pink', nameName = 'Replace', tagAdd = 'Pink', tagName = 'Add', setAll = 'Red'}
    if not alt_click then
        if buttonsData.nameCol == 'Pink' then
            buttonsData.nameCol = 'Orange'
            buttonsData.nameName = 'Prefix'

        elseif buttonsData.nameCol == 'Orange' then
            buttonsData.nameCol = 'Blue'
            buttonsData.nameName = 'Suffix'

        elseif buttonsData.nameCol == 'Blue' then
            buttonsData.nameCol = 'Pink'
            buttonsData.nameName = 'Replace'
        end
    else
        --print('!!!')
    end
    self.clearButtons()
    MakeButtons()
end

-- TAG OPTIONS -----------------------------------------------------------------
function b_func_tagType(obj, playercolor, alt_click)
    --local buttonsData = {tagAdd = 'Orange', tagName = 'Add', setAll = 'false'}
    if not alt_click then
        if buttonsData.tagAdd == 'Pink' then
            buttonsData.tagAdd = 'Orange'
            buttonsData.tagName = 'Replace'

        elseif buttonsData.tagAdd == 'Orange' then
            buttonsData.tagAdd = 'Blue'
            buttonsData.tagName = 'Remove'

        elseif buttonsData.tagAdd == 'Blue' then
            buttonsData.tagAdd = 'Purple'
            buttonsData.tagName = 'Clear'

        elseif buttonsData.tagAdd == 'Purple' then
            buttonsData.tagAdd = 'Pink'
            buttonsData.tagName = 'Add'
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