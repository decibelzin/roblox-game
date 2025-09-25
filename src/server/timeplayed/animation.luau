local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local usernameCache = {}

local Config = require(game.ReplicatedStorage.Shared.timeplayed)

function getUsernameAsync(userid: number)
  if usernameCache[userid] then -- already cached, return
    return usernameCache[userid]
  end
  local success: boolean, resultOrError: string = pcall(function ()
    return Players:GetNameFromUserIdAsync(userid)
  end)
  if not success then
    if Config.DO_DEBUG then
      warn(("TopTimePlayed Board: Error retrieving username of userid %d. Cause: %s"):format(userid, resultOrError))
    end
    return "Name not found"
  else
    usernameCache[userid] = resultOrError
    return resultOrError
  end
end

local PlayAnimationInRig = {}

PlayAnimationInRig.currentId = -1

-- Procurar pela animação em diferentes locais possíveis
local function findAnimation()
  local timePlayedModel = workspace:FindFirstChild("TimePlayedLeaderboard")
  if not timePlayedModel then return nil end
  
  -- Tentar encontrar AnimationToPlay diretamente no model
  local animation = timePlayedModel:FindFirstChild("AnimationToPlay")
  if animation then return animation end
  
  -- Tentar encontrar dentro do First Place Avatar
  local firstPlaceAvatar = timePlayedModel:FindFirstChild("First Place Avatar")
  if firstPlaceAvatar then
    animation = firstPlaceAvatar:FindFirstChild("AnimationToPlay")
    if animation then return animation end
  end
  
  if Config.DO_DEBUG then
    warn("TopTimePlayed Board: AnimationToPlay não encontrada no TimePlayedLeaderboard")
  end
  return nil
end

-- Procurar pelo rig em diferentes locais possíveis
local function findRig()
  local timePlayedModel = workspace:FindFirstChild("TimePlayedLeaderboard")
  if not timePlayedModel then return nil end
  
  -- Tentar encontrar Rig diretamente no model
  local rig = timePlayedModel:FindFirstChild("Rig")
  if rig then return rig end
  
  -- Tentar encontrar dentro do First Place Avatar
  local firstPlaceAvatar = timePlayedModel:FindFirstChild("First Place Avatar")
  if firstPlaceAvatar then
    rig = firstPlaceAvatar:FindFirstChild("Rig")
    if rig then return rig end
  end
  
  if Config.DO_DEBUG then
    warn("TopTimePlayed Board: Rig não encontrado no TimePlayedLeaderboard")
  end
  return nil
end

PlayAnimationInRig.animation = findAnimation()
PlayAnimationInRig.rig = findRig()

-- Se não encontrar os componentes necessários, desabilitar o sistema
if not PlayAnimationInRig.animation or not PlayAnimationInRig.rig then
  if Config.DO_DEBUG then
    warn("TopTimePlayed Board: Sistema de animação desabilitado - componentes não encontrados")
  end
  return PlayAnimationInRig -- Retornar um módulo vazio mas funcional
end

PlayAnimationInRig.rigCopy = PlayAnimationInRig.rig:Clone()
PlayAnimationInRig.rigCopyStorage = ServerStorage:FindFirstChild("TopTimePlayedLeaderboard_DancingRigStorage")
if not PlayAnimationInRig.rigCopyStorage then
  PlayAnimationInRig.rigCopyStorage = Instance.new("Folder", ServerStorage)
  PlayAnimationInRig.rigCopyStorage.Name = "TopTimePlayedLeaderboard_DancingRigStorage"
end
PlayAnimationInRig.rigCopy.Parent = PlayAnimationInRig.rigCopyStorage

function PlayAnimationInRig.StopAnimationTrack()
  if PlayAnimationInRig.animationTrack then
    PlayAnimationInRig.animationTrack:Stop()
    PlayAnimationInRig.animationTrack = nil
  end
end

function PlayAnimationInRig.AnimateRig()
  PlayAnimationInRig.StopAnimationTrack()
  PlayAnimationInRig.humanoid = PlayAnimationInRig.rig.Humanoid
  PlayAnimationInRig.rigAnimator = PlayAnimationInRig.humanoid.Animator
  PlayAnimationInRig.animationTrack = PlayAnimationInRig.rigAnimator:LoadAnimation(PlayAnimationInRig.animation)
  PlayAnimationInRig.animationTrack.Looped = true
  PlayAnimationInRig.animationTrack:Play()
end

function PlayAnimationInRig.SetRigHumanoidDescription(userId: number)
  if PlayAnimationInRig.currentId == userId then return end
  PlayAnimationInRig.currentId = userId
  PlayAnimationInRig.StopAnimationTrack()
  PlayAnimationInRig.rig:Destroy()
  PlayAnimationInRig.rig = PlayAnimationInRig.rigCopy:Clone()
  -- Definir o parent correto baseado em onde o rig original estava
  local timePlayedModel = workspace:FindFirstChild("TimePlayedLeaderboard")
  local firstPlaceAvatar = timePlayedModel and timePlayedModel:FindFirstChild("First Place Avatar")
  PlayAnimationInRig.rig.Parent = firstPlaceAvatar or timePlayedModel
  PlayAnimationInRig.AnimateRig()
  task.spawn(function ()
    local tries = 0
    local maxTries = 3
    local skip = false
    repeat
      local success, err = pcall(function ()
        local humanoidDescription
        local succ, err = pcall(function ()
          humanoidDescription = Players:GetHumanoidDescriptionFromUserId(userId)
          PlayAnimationInRig.humanoid:ApplyDescriptionReset(humanoidDescription)
        end)
        if not succ and Config.DO_DEBUG then
          warn(("TopTimePlayed Board: Failed to get humanoid description of userid %d. Cause: %s"):format(userId, err))
		end
		
        PlayAnimationInRig.humanoid.DisplayName = getUsernameAsync(userId)
      end)
      tries += 1
      if not success then warn(err) task.wait(1) end
      if success then skip = true end
    until tries > maxTries or skip == true
  end)
end

return PlayAnimationInRig
