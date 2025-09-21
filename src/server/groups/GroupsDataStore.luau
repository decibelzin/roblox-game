local DataStoreService = game:GetService("DataStoreService")
local GroupsStore = DataStoreService:GetDataStore("PlayerGroups")
local cache = {}

local DEFAULT_DATA = { groups = {} }

local function load(playerId)
    local key = tostring(playerId)
    local success, data = pcall(function()
        return GroupsStore:GetAsync(key)
    end)
    if success and data then
        cache[key] = data
    else
        cache[key] = table.clone(DEFAULT_DATA)
    end
    return cache[key]
end

local function save(playerId)
    local key = tostring(playerId)
    local data = cache[key]
    if not data then return end
    pcall(function()
        GroupsStore:SetAsync(key, data)
    end)
end

local GroupsData = {}

function GroupsData.Get(player)
    return cache[tostring(player.UserId)] or load(player.UserId)
end

function GroupsData.HasGroup(player, groupName)
    local data = GroupsData.Get(player)
    return data.groups[groupName] == true
end

function GroupsData.AddGroup(player, groupName)
    local data = GroupsData.Get(player)
    data.groups[groupName] = true
end

function GroupsData.RemoveGroup(player, groupName)
    local data = GroupsData.Get(player)
    data.groups[groupName] = nil
end

function GroupsData.Save(player)
    save(player.UserId)
end

function GroupsData.Load(player)
    return load(player.UserId)
end

return GroupsData
