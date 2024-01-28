local stringtools = require("/_libs/stringUtils/stringUtils")
local hexC = require("/_libs/stringUtils/stringColours")
local wait = require("/_libs/waitUtils/waitUtils")
local tabletools = require("/_libs/tableUtils/tableUtils")



local printSwitch = {obj = true, cards = false, colour = 'Blue', tooltip=': Result Printout :\nDECKS : DISABLED\nOBJECTS : ENABLED', proccessIdentSwitch = 'Red'}

function onload()
    -- SetScale
    if not self.getScale():equals(Vector(0.52, 0.79, 0.80)) then self.setScale(Vector(0.52, 0.79, 0.80)) end
    BuildHotKeys()
    MakeButtons()
end

--******************************************************************************
--** Edit the Tags of the Objects on the Tool **********************************
--******************************************************************************
function spawnEditedObject(Data, obj)
    --print_ProcessList(obj)
    local pos   = obj.getPosition()+Vector(0,4,0)
    local rot   = obj.getRotation()
    local scale = obj.getScale()

    destroyObject(obj)
    spawnObjectData({data = Data, position=pos, rotation=rot, scale=scale, sound=true})
end
--------------------------------------------------------------------------------
-- Clear or remove individual Tags ---------------------------------------------
function b_func_ClearRemoveTag(obj, playercolor, alt_click)
    local ObjectsOnTool = find_ObjectsOnTool()
    local TAGS = findTagsInDescriptionOfTool()

    if TAGS.foundRemove then
        if ObjectsOnTool.foundStuff then
            if not alt_click then
                editTags(ObjectsOnTool, TAGS, 'remove')
            else
                editTags(ObjectsOnTool, TAGS, 'remove', true)
            end
        else
            printToAll('\nERROR : There nothing on the tool to TAG!!', 'Red')
        end
    else
        if not alt_click then
            editTags(ObjectsOnTool, TAGS, 'remove')
        else
            printToAll('\nERROR : There are'..hexC.white..' NO REMOVE TAGS '..hexC.red..' in the DESCRIPTION FIELD', 'Red')
            printToAll('  Format : Add:TagName', 'Yellow')
            printToAll('(Place each Tag on a NEW LINE in the Description)\n', 'Orange')
        end
    end
end
--------------------------------------------------------------------------------
-- Edit the Tags based on the Data on the tools --------------------------------
function editTags(ObjectsOnTool, tags, switch, rightClick)
    local tagList = tags[switch]
    print_Start(switch, tagList, rightClick)
--- PROCESS OBJECTS
    print_Objects(ObjectsOnTool, tagList, switch, rightClick, 'OBJECTS')
    for _, obj in pairs(ObjectsOnTool.objects) do
        local Data = obj.getData()
        process_Objects(Data, tagList, setSwitch(switch), rightClick)
        setNameDecGM(Data, tags)
        print_ProcessList(obj,true)
        spawnEditedObject(Data, obj)
    end
--- PROCESS BAGS
    print_Objects(ObjectsOnTool, tagList, switch, rightClick, 'BAGS')
    for i, bag in pairs(ObjectsOnTool.bags) do
        if bag.getQuantity() > 0 then
            local Data = bag.getData()
            print_ProcessContainerList(bag, i, 'BAG  ')
            for k, objData in pairs (Data.ContainedObjects) do
                if objData.Name == 'Deck' then
                    process_Decks(objData, tags, tagList, setSwitch(switch), rightClick)
                else
                    process_Objects(objData, tagList, setSwitch(switch), rightClick)
                    setNameDecGM(objData, tags)
                    print_ProcessList(objData,false,'        ')
                end
            end
            spawnEditedObject(Data, bag)
        else
            local bagName = bag.getName()
            if bagName == '' then
                bagName = tostring(bag)
            end
            printToAll(hexC.red..' - Error :'..hexC.white..' '..bagName..hexC.yellow..' dose not contain any objects!')
        end
        --print('-------- !END PROCESS BAGS')
    end
--- PROCESS Decks
    print_Objects(ObjectsOnTool, tagList, switch, rightClick, 'DECKS')
    for i, deck in pairs(ObjectsOnTool.decks) do
        local Data = deck.getData()
        print_ProcessContainerList(deck, i, 'DECK')
        process_Decks(Data, tags, tagList, setSwitch(switch), rightClick)
        spawnEditedObject(Data, deck)
    end
end
--------------------------------------------------------------------------------
-- Use Switches to determin and then run the actual edit tag code --------------
function process_Decks(Data, tags, tagList, switch_addRemove, rightClick)
    print_ProcessDeck(Data)
    -- Process the Deck itself
    process_Objects(Data, tagList, switch_addRemove, rightClick)
    setNameDecGM(Data, tags)
    -- Process Cards
    for k, objData in pairs (Data.ContainedObjects) do
        process_Objects(objData, tagList, switch_addRemove, rightClick)
        setNameDecGM(objData, tags)
        if printSwitch.cards then print_ProcessList(objData,false,'                ') end
    end
end
--------------------------------------------------------------------------------
-- Use Switches to determin and then run the actual edit tag code --------------
function process_Objects(Data, tagList, switch_addRemove, rightClick)
    if isObjectTagged(Data) then
        if not rightClick then
            if switch_addRemove then
                Add_TagsToObject(Data, tagList)
                --print('====== process_Objects')
            else
                clear_TagsOnObjects(Data, tagList)
            end
        else
            if switch_addRemove then
                Replace_TagsOnObject(Data, tagList)
            else
                Remove_TagsOnObject(Data, tagList)
            end
        end
    else
        if switch_addRemove then
            Replace_TagsOnObject(Data, tagList)
        end
    end
    return Data
end
--------------------------------------------------------------------------------
-- Edit the getData() of the object to modify the Tags field in that table -----
function Add_TagsToObject(Data, tagList)
    for k,t in ipairs(tagList) do
        table.insert(Data.Tags, t)
    end
    tabletools.sortAlpha(Data.Tags)
end

function clear_TagsOnObjects(Data, tagList)
    Data.Tags = {}
    tabletools.sortAlpha(Data.Tags)
end

function Replace_TagsOnObject(Data, tagList)
    Data.Tags = tagList
    tabletools.sortAlpha(Data.Tags)
end

function Remove_TagsOnObject(Data, tagList)
    local Keep = {}
    local FinalTagList = {}

    for _,existingTag in ipairs(Data.Tags) do
        Keep[existingTag] = true
        for _,removeTag in ipairs(tagList) do
            if string.lower(existingTag) == string.lower(removeTag) then
                Keep[existingTag] = false
            end
        end
    end
    for _,tag in ipairs(Data.Tags) do
        if Keep[tag] then
            table.insert(FinalTagList, tag)
        end
    end
    Data.Tags = FinalTagList
    tabletools.sortAlpha(Data.Tags)
end
--------------------------------------------------------------------------------
-- Use GMNotes to edit the NAME, DESCRIPTION and GMnote of Objects Found on Tool
function setNameDecGM(Data, strList)
    if printSwitch.proccessIdentSwitch == 'Green' then
        if strList.foundDesc then
            local desciption = ''
            for k,s in ipairs(strList.desc) do
                if not strList.desc[k+1] then
                    desciption = desciption..s
                else
                    desciption = desciption..s..'\n'
                end
            end
            Data.Description = desciption
        end

        if strList.foundGMNote then
            local gmNote = ''
            for k,s in ipairs(strList.gm) do
                if not strList.gm[k+1] then
                    gmNote = gmNote..s
                else
                    gmNote = gmNote..s..'\n'
                end
            end
            Data.GMNotes = gmNote
        end

        if strList.foundName then
            if not strList.name.pos then
                Data.Nickname = strList.name.n
            else
                if strList.name.pos == '-' then
                    Data.Nickname = strList.name.n..Data.Nickname
                else
                    Data.Nickname = Data.Nickname..strList.name.n
                end
            end
        end
    end
end
--******************************************************************************
--*** Buttons ***** ************************************************************
--******************************************************************************
-- Change Colour of the Print out Option Button --------------------------------
function b_func_PrintSwitch()
    self.clearButtons()
    if printSwitch.obj and printSwitch.cards then
        printSwitch.obj   = false
        printSwitch.cards = false
        printSwitch.colour = 'Red'
        printSwitch.tooltip = ': Result Printout :\nDISABLED'
        MakeButtons()
    elseif not printSwitch.obj and not printSwitch.cards then
        printSwitch.obj   = true
        printSwitch.cards = false
        printSwitch.colour = 'Blue'
        printSwitch.tooltip = ': Result Printout :\nDECKS : DISABLED\nOBJECTS : ENABLED'
        MakeButtons()
    elseif printSwitch.obj and not printSwitch.cards then
        printSwitch.obj   = true
        printSwitch.cards = true
        printSwitch.colour = 'Green'
        printSwitch.tooltip = ': Full Result Printout :\nENABLED'
        MakeButtons()
    end
end
--------------------------------------------------------------------------------
-- Swap the SET IDENT Button between Green and Red -----------------------------
function b_func_SetProcessNameDesGM(obj, playercolor, alt_click)
    self.clearButtons()
    if printSwitch.proccessIdentSwitch == 'Red' then printSwitch.proccessIdentSwitch = 'Green'
    elseif printSwitch.proccessIdentSwitch == 'Green' then printSwitch.proccessIdentSwitch = 'Red'
    end
    MakeButtons()
end
--------------------------------------------------------------------------------
-- Spawn Bags on Tool ----------------------------------------------------------
function b_func_SpawnBags(obj, playercolor, alt_click)
    if not alt_click then
        wait.countClicks(self,spawnBags, 0.4)
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
--------------------------------------------------------------------------------
-- Edit the Tags of the Obejcts ------------------------------------------------
function b_func_AddReplaceTags(obj, playercolor, alt_click)
    local ObjectsOnTool = find_ObjectsOnTool()
    local TAGS = findTagsInDescriptionOfTool()
    --zprint(ObjectsOnTool,'ObjectsOnTool')
    if TAGS.foundAdd then
        if ObjectsOnTool.foundStuff then
            if not alt_click then
                editTags(ObjectsOnTool, TAGS, 'add')
            else
                editTags(ObjectsOnTool, TAGS, 'add', true)
            end
        else
            printToAll('\nERROR : There nothing on the tool to TAG!!', 'Red')
        end
    else
        printToAll('\nERROR : There are NO ADD TAGS in the DESCRIPTION FIELD', 'Red')
        printToAll('  Format : Add:TagName', 'Yellow')
        printToAll('(Place each Tag on a NEW LINE in the Description)\n', 'Orange')
    end
end
--******************************************************************************
--*** Hot Key Stuff ************************************************************
--******************************************************************************
function BuildHotKeys()
    addHotkey("Tags_Print",hot_PrintTags , false)

    addHotkey("Tags_ADD",hot_AddTags , false)
    addHotkey("Tags_REPLACE",hot_ReplaceTags , false)

    addHotkey("Tags_CLEAR",hot_ClearTags , false)
    addHotkey("Tags_REMOVE",hot_RemoveTags , false)

    addHotkey("Toggle ToolTip",hot_ToggleToolTips , false)
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

function hot_AddTags(playerColor, object, pointerPosition, isKeyUp)
    if object then
        local TAGS = findTagsInDescriptionOfTool()
        if TAGS.foundAdd then
            local name = object.getName()
            if name == '' then name = tostring(object) end
            printToAll('\n'..name, 'Orange')

            for k, tag in pairs(TAGS.add) do
                printToAll('   Adding : '..tag, 'Yellow')
                object.addTag(tag)
            end
            local tagTable = object.getTags()
            tabletools.sortAlpha(tagTable)
            object.setTags(tagTable)
        else
            printToAll('\nERROR : There are no tags in the DESCRIPTION FIELD', 'Red')
            printToAll('  Format : add:TagName', 'Yellow')
            printToAll('(Place each Tag on a NEW LINE in the Description)\n', 'Orange')
        end
    else
        printToAll('ERROR : There is no Object Under the Cursor', 'Red')
    end
end

function hot_ReplaceTags(playerColor, object, pointerPosition, isKeyUp)
    if object then
        local TAGS = findTagsInDescriptionOfTool()
        if TAGS.foundAdd then
            local name = object.getName()
            if name == '' then name = tostring(object) end
            printToAll('\n'..name, 'Orange')

            printToAll('   Clearing All Tags', 'Red')
            object.setTags({})
            for k, tag in pairs(TAGS.add) do
                printToAll('   Adding : '..tag, 'Yellow')
                object.addTag(tag)
            end
            local tagTable = object.getTags()
            tabletools.sortAlpha(tagTable)
            object.setTags(tagTable)
        else
            printToAll('\nERROR : There are no tags in the DESCRIPTION FIELD', 'Red')
            printToAll('  Format : add:TagName', 'Yellow')
            printToAll('(Place each Tag on a NEW LINE in the Description)\n', 'Orange')
        end
    else
        printToAll('ERROR : There is no Object Under the Cursor', 'Red')
    end
end

function hot_PrintTags(playerColor, object, pointerPosition, isKeyUp)
    if object then
        local objString = tostring(object)
        local nameString = object.getName()
        local tags = object.getTags()
        table.sort(tags)

        if nameString == '' then
            nameString = tostring(object)
        end

        printToAll('\n'..objString,'Orange')

        if tags[1] then
            if nameString == '' then
                printToAll('  Object Name : <No Name>', 'Yellow')
                for k,v in ipairs(tags) do
                    printToAll(' '..k..' : '..v)
                end
            else
                printToAll(' Object Name : '..nameString, 'Yellow')
                for k,v in ipairs(tags) do
                    printToAll(' '..k..' : '..v)
                end
            end
        else
            printToAll(' ERROR : There are no Tags on the object', 'Red')
            printToAll(' : \"'..nameString..'\"', 'Yellow')
        end
    end
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

function hot_RemoveTags(playerColor, object, pointerPosition, isKeyUp)
    if object then
        local TAGS = findTagsInDescriptionOfTool()
        if TAGS.foundRemove then
            local name = object.getName()
            if name == '' then name = tostring(object) end
            printToAll('\n'..name, 'Orange')

            for k, tag in pairs(TAGS.remove) do
                printToAll('   Removing : '..tag, 'Yellow')
                object.removeTag(tag)
            end
        else
            printToAll('\nERROR : There are no tags in the DESCRIPTION FIELD', 'Red')
            printToAll('  Format : remove:TagName', 'Yellow')
            printToAll('(Place each Tag on a NEW LINE in the Description)\n', 'Orange')
        end
    else
        printToAll('ERROR : There is no Object Under the Cursor', 'Red')
    end
end

--******************************************************************************
--*** Print Tools **************************************************************
--******************************************************************************

--------------------------------------------------------------------------------
-- Print contents of Deck Data -------------------------------------------------
function print_ProcessDeck(deckData)
    local name = deckData.Nickname
    if name == '' then name = deckData.Name end
    printToAll(hexC.pink..'       Proccessing Deck : '..hexC.white..name)
end
--------------------------------------------------------------------------------
-- Print the List of Containters (decks and bags) ------------------------------
function print_ProcessContainerList(bag, i, type)
    local name = bag.getName()
    if name == '' then name = tostring(bag) end
    printToAll(hexC.green..'   Proccessing '..type..' '..i..' : '..hexC.white..name)
end
--------------------------------------------------------------------------------
-- Print the PROCESS block -----------------------------------------------------
function print_ProcessList(obj, isObject, space)
    if printSwitch.obj then
        local name = ''
        local space = space or ''
        if isObject then
            name = obj.getName()
            if name == '' then name = tostring(obj) end
        else
            name = obj.Nickname
            if name == '' then name = obj.Name end
        end
        printToAll(space..hexC.yellow..'Proccessed : '..hexC.white..' : '..name)
    end
end
--------------------------------------------------------------------------------
-- Print Block of the Objects being Eedited ------------------------------------
function print_Objects(ObjectsOnTool, tagList, switch, rightClick, title)
    local type   = ''
    if switch == 'add' and not rightClick then
        type = 'ADD'
    elseif switch == 'add' and rightClick then
        type = 'REPLACE'
    elseif switch == 'remove' and not rightClick then
        type = 'CLEAR all'
    elseif switch == 'remove' and not rightClick then
        type = 'REMOVE named'
    end

    if title == 'OBJECTS' then
        if ObjectsOnTool.objects[1] then
            printToAll('\n'..title..' : '..type..' Tags', 'Orange')
        end
    elseif title == 'BAGS' then
        if ObjectsOnTool.bags[1] then
            printToAll('\n'..title..' : '..type..' Tags', 'Orange')
        end
    end
end
--------------------------------------------------------------------------------
-- Start the Print Block that outputs into chat what is happening --------------
function print_Start(switch, tagList, rightClick)
    local type   = ''
    local dashes = ''
    if switch == 'add' and not rightClick then
        type = 'ADD'
        dashes = '-----------------------------------'
    elseif switch == 'add' and rightClick then
        type = 'REPLACE'
        dashes = '---------------------------------------'
    elseif switch == 'remove' and not rightClick then
        type = 'CLEAR'
        dashes = '------------------------------------'
    elseif switch == 'remove' and rightClick then
        type = 'REMOVE NAMED '
        dashes = '-----------------------------------------------'
    end
    printToAll(hexC.green..'\n'..dashes..'\n   Start Processing : '..hexC.white..type..' TAGS'..hexC.green..'\n'..dashes)
    printToAll('   TAGS to '..type..':', 'White')
    for k,t in ipairs(tagList) do
        printToAll('         '..t, 'White')
    end
end
--******************************************************************************
--*** Tools ********************************************************************
--******************************************************************************
--------------------------------------------------------------------------------
-- Return TRUE or FLASE based on the switch to ADD or REMOVE -------------------
function setSwitch(type)
    if type == 'remove' then
        return false
    else
        return true
    end
end
--------------------------------------------------------------------------------
-- Make a true test to see if the object has Tags 9uses getData() --------------
function isObjectTagged(Data)
    for k, d in pairs (Data) do
        if k == 'Tags' then return true end
    end
    return false
end
--------------------------------------------------------------------------------
-- Find all Object and tool using a cast and return them.-----------------------
function find_ObjectsOnTool(pos, radius)
    local zone = Physics.cast({ origin=self.getPosition()+Vector(0,2.5,0),
                                direction={0,1,0},
                                type=3,
                                max_distance=0,
                                size={13.4,5,13.7},
                                debug=true})
    local Objects = {}
    local Bags   = {}
    local Decks   = {}
    local FoundStuff = false

    for k, found in pairs(zone) do
        local obj = found.hit_object
        if obj.type == 'Bag' then
            table.insert(Bags, obj)
            FoundStuff = true
        elseif obj.type == 'Deck' then
            table.insert(Decks, obj)
            FoundStuff = true
        elseif (obj.type ~= 'Surface') and (obj.memo ~= '___(Tool) - Add / Remove TagBag') then
            table.insert(Objects, obj)
            FoundStuff = true
        end
    end
    return {bags=Bags, decks=Decks, objects = Objects, foundStuff = FoundStuff}
end
--------------------------------------------------------------------------------
-- find the tags on the written into the tool ----------------------------------
function findTagsInDescriptionOfTool()
    --local TagTool = getObjectsWithTag('tool_EditTags')[1]
    --print(TagTool.getDescription())
    local z = {add={}, remove={}, foundAdd = false, foundRemove = false, name={pos=false, n=nil}, desc={}, gm={}, foundName = false, foundDesc = false, foundGMNote = false}
        local desc = stringtools.splitString(getObjectFromGUID('1ad5f6').getDescription())
        local GMnotes = stringtools.splitString(self.getGMNotes())
        local addTagsFoundinDesc = false

        for k, str in pairs(desc) do
            if string.find(string.lower(str), 'add:', 1, true) then
                z.foundAdd = true
                break
            end
        end

        for k, str in pairs(desc) do
            if string.find(string.lower(str), 'remove:', 1, true) then
                z.foundRemove = true
                break
            end
        end

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

        for k, str in pairs(GMnotes) do
            if string.find(string.lower(str), 'name:', 1, true) then
                z.foundName = true
                break
            end
        end

        for k, str in pairs(GMnotes) do
            if string.find(string.lower(str), 'desc:', 1, true) then
                z.foundDesc = true
                break
            end
        end

        for k, str in pairs(GMnotes) do
            if string.find(string.lower(str), 'gm:', 1, true) then
                z.foundGMNote = true
                break
            end
        end

        for k, str in pairs(GMnotes) do
            if string.find(string.lower(str), 'name:', 1, true) then
                local line = str
                local p = string.sub(str, 1, 1)
                if string.lower(p) == 'n' then
                    z.name.pos = false
                    line = line:sub(6)
                else
                    z.name.pos = string.lower(p)
                    line = line:sub(7)
                end
                z.name.n = line

            elseif string.find(string.lower(str), 'desc:', 1, true) then
                local line = str:sub(6)
                table.insert(z.desc, line)

            elseif string.find(string.lower(str), 'gm:', 1, true) then
                local line = str:sub(4)
                table.insert(z.gm, line)
            end
        end
    tabletools.sortAlpha(z.add)
    --print('!! -------------------------- !!')
    --print(logString(z))
    return z
end
--******************************************************************************
--*** MakeButtons **************************************************************
--******************************************************************************
function MakeButtons(colour, tooltip)
    self.createButton({
        label='Add Tags\n(Right Click : Replace Tags)',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_AddReplaceTags", function_owner=self,
        position={0,0.6,10.2}, rotation={0,0,0}, height=650, width=3500,
        font_size=250, scale={1.5,1.5,1.5}--, color={0,0,0}, font_color={1,1,1}
    })

    self.createButton({
        label='Clear Tags\n(Right Click : Remove Individual Tags)',-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_ClearRemoveTag", function_owner=self,
        position={0,0.6,12.3}, rotation={0,0,0}, height=650, width=4500,
        font_size=250, scale={1.5,1.5,1.5}--, color={0,0,0}, font_color={1,1,1}
    })

    self.createButton({
        label='Spawn Bags', tooltip="Spawns a Bags",
        click_function="b_func_SpawnBags", function_owner=self,
        position={6.5,0.6,-9.5}, rotation={0,0,0}, height=550, width=2000,
        font_size=250, scale={1.2,1.2,1.2}--, color={0,0,0}, font_color={1,1,1}
    })

    --if not colour then colour = 'Green' end
    --local colour = colour or 'Blue'
    --local tooltip = tooltip or 'Full Result Printout : ENABLED'
    self.createButton({
        label='Print Results', tooltip=printSwitch.tooltip,
        click_function="b_func_PrintSwitch", function_owner=self,
        position={-6.5,0.6,-9.5}, rotation={0,0,0}, height=550, width=2000,
        color=printSwitch.colour, font_color='White',
        font_size=250, scale={1.2,1.2,1.2}--, color={0,0,0}, font_color={1,1,1}
    })

    self.createButton({
        label='Ident Data', tooltip="If green it will use the NAME, DESCRIPTION and GMNOTE tags on Tool to populate those fields on the Object\n(see Mod Notes inside Mod or Workshop)",
        click_function="b_func_SetProcessNameDesGM", function_owner=self,
        position={0,0.6,-9.5}, rotation={0,0,0}, height=550, width=2000,
        font_size=250, scale={1.2,1.2,1.2}, color=printSwitch.proccessIdentSwitch, font_color='White'
    })
end

-- require("_tools/TagEditor/AddRemoveTags_DATA")
