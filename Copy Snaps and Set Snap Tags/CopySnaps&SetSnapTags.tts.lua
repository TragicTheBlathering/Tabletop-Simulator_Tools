--******************************************************************************
--*** Variables needed throughout the entire obj Script (sudo global) **********
--******************************************************************************
local ShowCast = false
local CopyGUID = {name = 'Copy Snaps from', foundGUID = '<Not Set>', colour='Red'}
local Platform_Tag = 'CopySnaps_Platform'
local TagType = {name = 'Replace', colour = 'Orange'}
local setViaZone = {name='Set Tags Via Script Zone', colour='Red'}
local scaleSwitch = {name = 'Preserve Scale', colour = 'Orange'}
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
local TimerID = nil

function onLoad(save_state)
    BuildHotKeys()
    MakeButtons()
    TimerID_SetName = Wait.time(SetButtonNameCOPY, 2,-1)
    TimerID_SetName = Wait.time(SetButtonNameZONE, 2,-1)
end
--******************************************************************************
--*** Edit SNAP TAGS from SCRIPT ZONE ******************************************
--******************************************************************************
function b_func_tagScriptZone()
    if setViaZone.colour == 'Green' then
        TagSnapsViaZone()
    else
        printToAll(hexC.red..'ERROR : '..hexC.yellow..'No ScriptZones....\n  Make 1 or more ScriptZones, tagged as :'..hexC.orange..' tagTool_ScriptZone')
    end
end

function TagSnapsViaZone()
    local targets = {objs = {}, zones = {}, ofound = false, zfound = false}
    local objects = {}
    for k,zone in pairs(getObjectsWithTag('tagTool_ScriptZone')) do
        targets.zfound = true
        table.insert(targets.zones, zone)
        for k,o in pairs(zone.getObjects(true)) do
            targets.ofound = true
            objects[o] = o
        end
    end
    for k,o in pairs(objects) do
        table.insert(targets.objs, o)
    end


    if snapsTargetsFound(targets) then
        local tagsList, found = setTagsforSnapsFromZone()
        if found then
            findBoundingBox(targets, tagsList)
        end
        printSnapResults(tagsList)
    end
end

function printSnapResults(tagsList)
    local action = TagType.name
    if action == 'Clear' then
        printToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have been : '..hexC.green..'CLEARED')

    elseif action == 'Replace' then
        if tagsList.TagList.add[1] then
            printToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have been : '..hexC.green..'REPLACED')
            --print(logString(tagsList.TagList.add, '---- Tags Added to Snaps ----'))
        else
            printToAll(hexC.red..'ERROR : '..hexC.white..'No tags to use for reaplce found on NoteCard')
        end

    elseif action == 'Add' then
        if tagsList.TagList.add[1] then
            --print('!!!')
            printToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have had their existing tags : '..hexC.green..'ADDED TO')
            --print(logString(tagsList.TagList.add, '---- Tags Added to Snaps ----'))
        else
            printToAll(hexC.red..'ERROR : '..hexC.white..'No tags to add found on NoteCard')
        end

    elseif action == 'Remove' then
        if tagsList.TagList.remove[1] then
            printToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have had some tags : '..hexC.green..'REMOVED')
            --print(logString(tagsList.TagList.remove, '---- Tags Removed from Snaps ----'))
        else
            printToAll(hexC.red..'ERROR : '..hexC.white..'No tags to remove found on NoteCard')
        end
    end

end

function findBoundingBox(targets, tags)
    --print(logString(tags, '\n--- findBoundingBox ----'))
    for _,o in pairs(targets.objs) do
        for k,z in pairs(targets.zones) do
            setSnapTagsInZone(o,z, tags)
        end
    end
    return nil
end

function setSnapTagsInZone(obj,zone, tagsList)

    --print(logString(tagsList.TagList.add, '\n---- setSnapTags.add ----'))

    local action = TagType.name

    local zBounds = getZBounds(zone)
    local areaOffset = (Vector(divide_preserveSign(zBounds.size.x, 2), divide_preserveSign(zBounds.size.y, 2), divide_preserveSign(zBounds.size.z, 2)))

    local zoneArea_WorldPoints = {upperLeft  = Vector(zone.getPosition().x - areaOffset.x, 5, zone.getPosition().z + areaOffset.z),
    lowerRight = Vector(zone.getPosition().x + areaOffset.x, 5, zone.getPosition().z - areaOffset.z)}

    local snaps = obj.getSnapPoints()
    for i, snap in ipairs(snaps) do
        local snapPosLocal = snap.position
        local snapPosWorld = obj.positionToWorld( snapPosLocal )

        --local testSnapPos = spawnObject({type='BlockSquare', position=Vector(snapPosWorld.x, 5, snapPosWorld.z)})

        if insideArea(snapPosWorld, zoneArea_WorldPoints) then
            local snapTags = snaps[i].tags
            if action == 'Clear' then
                snaps[i].tags = {}
                --print('CLEAR TAGS')
                --broadcastToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have been : '..hexC.green..'CLEARED')

            elseif action == 'Replace' then
                if tagsList.TagList.add[1] then
                    snaps[i].tags = tagsList.TagList.add
                    --broadcastToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have been : '..hexC.green..'REPLACED')
                    --print(logString(tagsList.TagList.add, '---- Tags Added to Snaps ----'))
                else
                    --printToAll(hexC.red..'ERROR : '..hexC.white..'No tags to use for reaplce found on NoteCard')
                end

            elseif action == 'Add' then
                if tagsList.TagList.add[1] then
                    for k, t in pairs(tagsList.TagList.add) do
                        table.insert(snaps[i].tags, t)
                    end
                    --printToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have had their existing tags : '..hexC.green..'ADDED TO')
                    --print(logString(tagsList.TagList.add, '---- Tags Added to Snaps ----'))
                else
                    --printToAll(hexC.red..'ERROR : '..hexC.white..'No tags to add found on NoteCard')
                end

            elseif action == 'Remove' then
                if tagsList.TagList.remove[1] then
                    local new = {}
                    for k,otag in pairs (snaps[i].tags) do
                        for k, ntag in pairs(tagsList.TagList.remove) do
                            if string.lower(otag) ~= string.lower(ntag) then
                                table.insert(new, otag)
                            end
                        end
                    end
                    snaps[i].tags = new
                    --broadcastToAll(hexC.orange..'All'..hexC.yellow..' Snaps'..hexC.orange..' found inside'..hexC.yellow..' Zone'..hexC.orange..' have had some tags : '..hexC.green..'REMOVED')
                    --print(logString(tagsList.TagList.remove, '---- Tags Removed from Snaps ----'))
                else
                    --printToAll(hexC.red..'ERROR : '..hexC.white..'No tags to remove found on NoteCard')
                end
            end
            table.sort(snaps[i].tags)
        end
    end
    obj.setSnapPoints(snaps)
end

function insideArea(snap, area)
    if snap.x <= area.upperLeft.x
    or snap.z >= area.upperLeft.z
    or snap.x >= area.lowerRight.x
    or snap.z <= area.lowerRight.z
    then
        return false
    end
    return true
end

function divide_preserveSign(num, div)
  local sign = num >= 0 and 1 or -1 -- determine the sign of the number
  --local result = math.floor(math.abs(num) / div) * sign -- divide the absolute value of the number by 2 and multiply by the sign
  local result = num / div * sign -- divide the absolute value of the number by 2 and multiply by the sign
  return result
end

function getZBounds( obj )

    local IS_ZONE_LOOKUP = {
                    FogOfWar         = true,
                    FogOfWarTrigger  = true,
                    RandomizeTrigger = true,
                    ScriptingTrigger = true,
                    -- No objects for hand zone.
                    }

    function is_zone( obj )
        return IS_ZONE_LOOKUP[ obj.name ]
    end


   local bounds = obj.getBounds()

   if is_zone( obj ) then
      local rotation = obj.getRotation()
      local size =
         obj.getScale()
         :rotateOver( 'z', rotation.z )
         :rotateOver( 'x', rotation.x )
         :rotateOver( 'y', rotation.y )

      bounds.size = Vector(
         math.abs( size.x ),
         math.abs( size.y ),
         math.abs( size.z )
      )
   end

   return bounds
end

function setTagsforSnapsFromZone()
    local type = 'CopySnaps_Platform'
    local tags = nil
    local plat = getObjectsWithTag(type)[1]
        if plat then
            tags = cast(plat, 'noteCard')
            --print(logString(tags, '---- TAGS ----'))
        end

    if not tags then
        return tags, false
    else
        if not tags.TagList.add[1] and not tags.TagList.remove[1] then
            local found = false
            if TagType.name == 'Clear' then
                found = true
            end
            return tags, found
        end
    end

    return tags, true
end

function snapsTargetsFound(tar)
    if tar.zfound then
        if tar.ofound then
            return true
        else
            printToAll(hexC.red..'Error : '..hexC.white..' Zone Found but no Object found inside it')
        end
    else
        printToAll(hexC.red..'Error : '..hexC.white..' You need to draw a ScriptZone and tag it as :'..hexC.yellow..' tagTool_ScriptZone')
    end
    return false
end

--******************************************************************************
--*** Copy Snaps  **************************************************************
--******************************************************************************
function b_func_CopySnaps(obj, playercolor, alt_click)
    if CopyGUID.foundGUID ~= '<Not Set>' then -- Check GUID is set
        local sourceObj = getObjectFromGUID(CopyGUID.foundGUID)
        if sourceObj ~= nil then -- check GUIDis valid
            local foundObjectsToEdit = cast(self, 'mainTool', '', Vector(15.8,5,15.8))
            local sourceSnapData = findSnapsOnSource(sourceObj)
            if sourceSnapData.snaps ~= nil then
                applySourceSnaps(sourceSnapData, foundObjectsToEdit)
            else
                printToAll(hexC.red..'Error : '..hexC.yellow..'No Snap Points found on Source Object')
            end
        else
            printToAll(hexC.red..'Error : '..hexC.yellow..'Invalid GUID in Description of Tool')
        end
    else
        printToAll(hexC.red..'Error : '..hexC.yellow..'You must past a'..hexC.orange..' GUID'..hexC.yellow..' form your source OBJ into the Description of the tool')
    end
end

function applySourceSnaps(sourceSnapData, foundObjectsToEdit)

    for type, data in pairs(foundObjectsToEdit) do
        if type == 'objs' then
            for obj, o in pairs(data) do
                o.AttachedSnapPoints = sourceSnapData.snaps
                if scaleSwitch.name == 'Copy Scale' then
                    o.Transform.scaleX = sourceSnapData.scale.x
                    o.Transform.scaleY = sourceSnapData.scale.y
                    o.Transform.scaleZ = sourceSnapData.scale.z
                end
            end
        elseif type == 'bags' or type == 'decks' then
            for bag, data in pairs(data) do
                for k, o in pairs(data.ContainedObjects) do
                    --print(logString(o.AttachedSnapPoints, '\n ----- '..o.Nickname..' -----'))
                    o.AttachedSnapPoints = sourceSnapData.snaps
                    if scaleSwitch.name == 'Copy Scale' then
                        o.Transform.scaleX = sourceSnapData.scale.x
                        o.Transform.scaleY = sourceSnapData.scale.y
                        o.Transform.scaleZ = sourceSnapData.scale.z
                    end
                end
            end

        elseif type == 'decks' then

        end
    end

    for type, list in pairs(foundObjectsToEdit) do
        for obj, d in pairs(list) do
            --print(k)
            local pos = Vector(d.Transform.posX, d.Transform.posY, d.Transform.posZ)
            destroyObject(obj)
            spawnObjectData({data=d, position=pos+Vector(0,3,0)})
        end
    end
end

function findSnapsOnSource(sourceObj)
    local sourceData = sourceObj.getData()
    local editedData = assignSnapTags(sourceObj, sourceData)

    local snapData = {snaps = editedData.AttachedSnapPoints, scale = Vector(sourceData.Transform.scaleX, sourceData.Transform.scaleY, sourceData.Transform.scaleZ)}
    return snapData
end

function assignSnapTags(sourceObj, sourceData)
    local snapObjects = cast(sourceObj, 'findSnapTags')
    local returnData = sourceData
    --print(logString(snapObjects, '\n snapObjects'))

    if tableSize(snapObjects) > 0 then
        if returnData.AttachedSnapPoints ~= nil then
            --print(logString(returnData.AttachedSnapPoints, '\n --- sourceData.AttachedSnapPoints ---'))
            for k,snap in pairs(returnData.AttachedSnapPoints) do
                local snapPosWorld = sourceObj.positionToWorld( snap.Position )
                for k,obj in pairs(snapObjects) do
                    --print(logString(obj, '\n --- OBJECT DATA ---'))
                    local oPos = obj.snapedObj.getPosition()
                    local tags = obj.snapTags
                    if equalVec_NoY(snapPosWorld, oPos) then
                        --print(logString(tags, '\n --- tags ---'))
                        --print(snapPosWorld)
                        --print(o.snapedObj.getPosition())
                        if snap.Tags == nil then
                            snap.Tags = tags
                        else
                            for q,w in pairs(tags) do
                                table.insert(snap.Tags, w)
                            end
                        end
                    end
                end
            end
        end
    end
    return returnData
end

function equalVec_NoY(v1, v2)
    local vec1 = Vector(v1.x, 0, v1.z)
    local vec2 = Vector(v2.x, 0, v2.z)
    return vec1:equals(vec2)
end

--******************************************************************************
--*** Cast Functions  **********************************************************
--******************************************************************************
function cast(target, switch, vec)
    --print('--- CAST FUNCTION -------------------------------------------------')
    vec = vec or Vector(1,1,1)
    local platform = {posOffset = nil, size = vec}

    if switch == 'mainTool' then
        platform.size = Vector(15.8,5,15.8)
        platform.posOffset=Vector(0, 2.85, 0)

    elseif switch == 'findSnapTags' then
        local bounds = target.getBoundsNormalized()
        platform.size = Vector(bounds.size.x, bounds.size.y+0.2, bounds.size.z)
        platform.posOffset=Vector(0, 0.1, 0)

    elseif switch == 'noteCard' then
        platform = {size=vec, posOffset=Vector(0, 0.85, 0)}
    end
    local size = platform.size
    local zone = Physics.cast({ origin=target.getPosition() + platform.posOffset,
                                direction={0,1,0},
                                type=3,
                                max_distance=0,
                                size=size,
                                debug=ShowCast})
    return processCast(zone, switch, target)
end

function processCast(zone, switch, target)
    --print('--- processCast FUNCTION ------------------------------------------')
    --print(logString(zone,'\n ZONE'))
    if switch == 'mainTool' then
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

    elseif switch == 'findSnapTags' then
        local data = {}
        for k,o in pairs(zone) do
            local obj = o.hit_object
            if (obj ~= target) and (obj.type ~= 'Surface') then
                if obj.interactable == true then
                    local snappedTags = {}
                    for k, tag in pairs(obj.getTags()) do
                        if string.find(string.lower(tag), string.lower('snapTag_'), 1, true) then
                            table.insert(snappedTags, tag)
                        end
                    end
                    table.insert(data, {snapedObj=obj, snapTags=snappedTags})
                end
            end
        end
        return data

    elseif switch == 'noteCard' then -- CopySnaps_Platform
        local z = {found = false, data = {}}
        for k,o in pairs(zone) do
            --print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
            if o.hit_object.type == 'Notecard' then
                local cardData = o.hit_object.getData()
                z.found = true
                z.data.TagList = extract_Tags(splitString(cardData.Description))
                z.data.obj = o.hit_object
                --print(logString(z.data.TagList.add, '\n --- z.data.TagList ---'))
            end
        end

        if z.found then
            --print('FOUND')
            return z.data
        else
            --print('NO')
            return false
        end
    end
end

function extract_Tags(data)
    local list = {add = {}, remove = {}}
    for k,line in pairs(data) do
        if line:sub(1, 2) ~= '--' then
            --local key, value = splitAtFirstNonOccurrence(line, ':')
            local split = useFirstOnly(splitString(line, ':'))
            local key = split[1]
            local value = split[2]
            if string.lower(key) == 'add' then
                table.insert(list.add, value)
            elseif string.lower(key) == 'remove' then
                table.insert(list.remove, value)
            end
        end
    end
    return list
end

function useFirstOnly(stringList)
    local nStr = ''
    if #stringList > 2 then
        for i = 2,#stringList,1 do
            nStr = nStr..stringList[i]
            if i < #stringList then
                nStr = nStr..':'
            end
            --print(logString(stringList, '\n----- stringList -----'))
        end
        return {stringList[1],nStr}
    else
        return stringList
    end
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
--*** Tools  *******************************************************************
--******************************************************************************
--------------------------------------------------------------------------------
--- Table Tools ----------------------------------------------------------------
function tableSize(t)
    if t then
        local count = 0
        for key,value in pairs(t) do count = count + 1 end
        return count
    else
        return 0
    end
end
--------------------------------------------------------------------------------
--- Wait Tools -----------------------------------------------------------------
function countClicks(obj,func,delay)
    --print('IN : waitUtils.countClicks')
    local delay = delay or 0.8 -- better way of setting default parameters
    Wait_ids[obj] = Wait_ids[obj] or { -- just to be sure there's no attempt to index a nil value later we set an empty table first.
      count = 0, -- We set the count to 0 here when the table is made
    }

    function delayCall()
        func(Wait_ids[obj].count)
        Wait_ids[obj].waitID = nil -- remove the wait id when the function is called
        Wait_ids[obj].count = 0  -- We set the count to 0 here when the wait has ended due to timeout
    end

    if Wait_ids[obj].waitID then Wait.stop(Wait_ids[obj].waitID); Wait_ids[obj].waitID = nil end -- end the previous wait if it exists
    Wait_ids[obj].waitID = Wait.time(delayCall, delay) -- make a new wait, but with _no_ count

    Wait_ids[obj].count = Wait_ids[obj].count + 1 -- finally increment the click amount.
end

--******************************************************************************
--*** Spawn Buttons ************************************************************
--******************************************************************************
--------------------------------------------------------------------------------
-- Spawn Bags on Tool ----------------------------------------------------------
function b_func_SpawnBags(obj, playercolor, alt_click)
    if not alt_click then
        countClicks(self,spawnBags, 0.4)
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
-- Spawn Platforms -------------------------------------------------------------
function b_func_SpawnPlatform(obj, playercolor, alt_click)
    if not alt_click then
        for _, o in pairs(getObjectsWithTag(Platform_Tag)) do
            destroyObject(o)
        end

        local adjustPos = Vector(-11.5, 0, 6)
        local platData = self.getData()
              platData.Nickname = 'Edit Tags'
              platData.GMNotes = ''
              platData.Memo = ''
              platData.LuaScript = ''
              platData.Tooltip = true
              platData.Tags = {Platform_Tag}

        local pos = self.getPosition() + adjustPos
        local rot = self.getRotation()
        local scale = Vector(0.35, 1, 0.25)

        local newObj = spawnObjectData({data = platData, position=pos, rotation=rot, scale=scale, sound=true})
        newObj.setSnapPoints({{position = {0, 0, 0}, rotation = {0, 0, 0},rotation_snap = true}})

    else
        for _, o in pairs(getObjectsWithTag(Platform_Tag)) do
            destroyObject(o)
        end
    end
end

--------------------------------------------------------------------------------
-- Spawn NoteCards -------------------------------------------------------------
function b_func_SpwanNoteCards(obj, playercolor, alt_click)
    local pos = self.getPosition()+Vector(-5.56, 2, 12.26)
    local rot = Vector(0,0,0)
    local scale = Vector(0.75,0.75,0.75)
    local offSet = Vector(0,0.3,0)
    spawnObject({type='notecard', position=pos+offSet, rotation=rot, scale=scale, sound=true})
end
--******************************************************************************
--*** Make Buttons *************************************************************
--******************************************************************************
function b_func_none()end
function MakeButtons(colour, tooltip)
-- Process Button --------------------------------------------------------------
    self.createButton({
            label=CopyGUID.name..' : '..CopyGUID.foundGUID,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_CopySnaps", function_owner=self,
            position={3.5,0.6,-9.15}, rotation={0,180,0}, height=550, width=4300,
            font_size=250, scale={1,1,1}, color=CopyGUID.colour, font_color={1,1,1}
            })
            self.createButton({
                label=scaleSwitch.name,-- tooltip="Place items to edit in a bag and place on tool",
                click_function="b_func_ScaleOrNot", function_owner=self,
                position={3.5,0.6,-10.3}, rotation={0,180,0}, height=550, width=2000,
                font_size=250, scale={0.8,0.8,0.8}, color=scaleSwitch.colour, font_color={1,1,1}
                })

    self.createButton({
        label=setViaZone.name,-- tooltip="Place items to edit in a bag and place on tool",
        click_function="b_func_tagScriptZone", function_owner=self,
        position={-4.5,0.6,-9.15}, rotation={0,180,0}, height=550, width=3100,
        font_size=250, scale={1,1,1}, color=setViaZone.colour, font_color={1,1,1}
        })
        self.createButton({
            label=TagType.name,-- tooltip="Place items to edit in a bag and place on tool",
            click_function="b_func_tagType", function_owner=self,
            position={-4.5,0.6,-10.3}, rotation={0,180,0}, height=550, width=1600,
            font_size=250, scale={0.8,0.8,0.8}, color=TagType.colour, font_color={1,1,1}
            })
--------------------------------------------------------------------------------
-- Spawn Bags ------------------------------------------------------------------
    self.createButton({
        label='Spawn Bags', tooltip="Spawns a Bags",
        click_function="b_func_SpawnBags", function_owner=self,
        position={-5.5,0.6,8.9}, rotation={0,180,0}, height=550, width=2000,
        font_size=250, scale={1,1,1}--, color={0,0,0}, font_color={1,1,1}
        })
-- Spawn Platforms -------------------------------------------------------------
    self.createButton({
        label='Spawn Platform', tooltip="Spawns a Bags",
        click_function="b_func_SpawnPlatform", function_owner=self,
        position={0,0.6,8.9}, rotation={0,180,0}, height=550, width=2500,
        font_size=250, scale={1,1,1}--, color={0,0,0}, font_color={1,1,1}
    })
-- Spawn NoteCards -------------------------------------------------------------
    self.createButton({
        label='Spawn NoteCard',-- tooltip=printSwitch.tooltip,
        click_function="b_func_SpwanNoteCards", function_owner=self,
        position={5.5,0.6,8.9}, rotation={0,180,0}, height=550, width=2300,
        color='White', font_color='Black',
        font_size=250, scale={1,1,1}--, color={0,0,0}, font_color={1,1,1}
    })

end

function b_func_ScaleOrNot(obj, playercolor, alt_click)
    if scaleSwitch.name == 'Preserve Scale' then
        scaleSwitch.colour = 'Blue'
        scaleSwitch.name = 'Copy Scale'

    elseif scaleSwitch.name == 'Copy Scale' then
        scaleSwitch.colour = 'Orange'
        scaleSwitch.name = 'Preserve Scale'
    end
    self.clearButtons()
    MakeButtons()
end
-- TAG OPTIONS -----------------------------------------------------------------
function b_func_tagType(obj, playercolor, alt_click)
    if TagType.colour == 'Purple' then
        TagType.colour = 'Orange'
        TagType.name = 'Replace'

    elseif TagType.colour == 'Orange' then
        TagType.colour = 'Red'
        TagType.name = 'Clear'

    elseif TagType.colour == 'Red' then
        TagType.colour = 'Blue'
        TagType.name = 'Add'

    elseif TagType.colour == 'Blue' then
        TagType.colour = 'Purple'
        TagType.name = 'Remove'
    end
    self.clearButtons()
    MakeButtons()
end

-- Button Dysnamic Name --------------------------------------------------------
function SetButtonNameCOPY()
    local inputGUID = self.getDescription()
    if CopyGUID.foundGUID == '<Not Set>' then
        if inputGUID ~= '' then
            CopyGUID.foundGUID = inputGUID
            CopyGUID.colour = 'Green'
            self.clearButtons()
            MakeButtons()
        end
    else
        if CopyGUID.foundGUID ~= inputGUID then
            if inputGUID == '' then
                CopyGUID.foundGUID = '<Not Set>'
                CopyGUID.colour = 'Red'
            else
                CopyGUID.foundGUID = inputGUID
            end
            self.clearButtons()
            MakeButtons()
        end
    end
end

function SetButtonNameZONE()
    local found = false
    for k,zone in pairs(getObjectsWithTag('tagTool_ScriptZone')) do
        found = true
        break
    end

    if found then
        setViaZone.colour = 'Green'
        self.clearButtons()
        MakeButtons()
    else
        setViaZone.colour = 'Red'
        self.clearButtons()
        MakeButtons()
    end
end
--******************************************************************************
--*** Hot Key Stuff ************************************************************
--******************************************************************************
function BuildHotKeys()
    addHotkey("Tags_Print",hot_PrintTags , false)
    addHotkey("Tags_CLEAR",hot_ClearTags , false)
    addHotkey("Toggle ToolTip",hot_ToggleToolTips , false)
    addHotkey("Tags_ADD",hot_AddTags , false)
    addHotkey("Tags_REPLACE",hot_ReplaceTags , false)
    addHotkey("Tags_REMOVE",hot_RemoveTags , false)
end

function PrintTargets(objString, nameString, object)
    local objString = tostring(object)
    local nameString = object.getName()
    if nameString == '' then nameString = '<No Name>' end

    printToAll('\n'..objString,'Orange')
    printToAll(' Object Name : '..nameString, 'Yellow')
end

function findTagsFromHotKey()
    local found = false
    local tags = {}
    local plat = getObjectsWithTag(Platform_Tag)[1]
    if plat ~= nil then
        tags = cast(plat, 'noteCard')
        if tags == false then
            found = false
        else
            if tags.TagList.add[1] ~= nil or  tags.TagList.remove[1] ~= nil then
                found = true
            end
        end
    end
    return found, tags
end

function hot_RemoveTags(playerColor, object, pointerPosition, isKeyUp)
    local found, tags = findTagsFromHotKey()
    if found then
        PrintTargets(objString, nameString, object)
        EditTags_ViaHotKEY('Remove', tags, object)
    else
        printToAll(hexC.red..' - ERROR : '..hexC.yellow..'No'..hexC.orange..' Platform'..hexC.yellow..' or'..hexC.orange..' NoteCard'..hexC.yellow..' Data Found')
    end
end

function hot_ReplaceTags(playerColor, object, pointerPosition, isKeyUp)
    local found, tags = findTagsFromHotKey()
    if found then
        PrintTargets(objString, nameString, object)
        EditTags_ViaHotKEY('Replace', tags, object)
    else
        printToAll(hexC.red..' - ERROR : '..hexC.yellow..'No'..hexC.orange..' Platform'..hexC.yellow..' or'..hexC.orange..' NoteCard'..hexC.yellow..' Data Found')
    end
end

function hot_AddTags(playerColor, object, pointerPosition, isKeyUp)
    local found, tags = findTagsFromHotKey()
    if found then
        PrintTargets(objString, nameString, object)
        EditTags_ViaHotKEY('Add', tags, object)
    else
        printToAll(hexC.red..' - ERROR : '..hexC.yellow..'No'..hexC.orange..' Platform'..hexC.yellow..' or'..hexC.orange..' NoteCard'..hexC.yellow..' Data Found')
    end
end

function hot_ClearTags(playerColor, object, pointerPosition, isKeyUp)
    PrintTargets(objString, nameString, object)
    EditTags_ViaHotKEY('Clear', tags, object)
end

function EditTags_ViaHotKEY(action, tags, object)
    if action == 'Clear' then
        printToAll(' Clearing all Tags on Object')
        object.setTags({})

    elseif action == 'Replace' then
        local newTags = tags.TagList.add
        table.sort(newTags)
        printToAll(' Replacing Exiting Tags With : ')
        for k,v in ipairs(newTags) do
            printToAll(' '..k..' : '..v)
        end
        object.setTags(newTags)

    elseif action == 'Add' then
        local newTags = tags.TagList.add
        printToAll(' Adding to Existing Tags : ')
        for k,v in ipairs(newTags) do
            printToAll(' '..k..' : '..v)
        end

        local oldTags = object.getTags()
        for k,v in pairs(oldTags) do
            table.insert(newTags, v)
        end
        table.sort(newTags)
        printToAll('\n New Tag List : ')
        for k,v in ipairs(newTags) do
            printToAll(' '..k..' : '..v)
        end

        object.setTags(newTags)

    elseif action == 'Remove' then
        local newTags = tags.TagList.remove
        for k,v in ipairs(newTags) do
            printToAll('Removing Tags : ')
            printToAll(' '..k..' : '..v)
            object.removeTag(v)
        end
    end
end
--[[

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
--]]

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
