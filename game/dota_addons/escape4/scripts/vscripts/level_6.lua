Waves = Waves or {}
local center
local boss
local r1 = 900
local r2 = 2500

local patrolMsStart = 300

local patrolsTable = {}
local tombstoneTable = {}

-- This function is for the final boss logic
function barebones:FinalBossThinker()
  print("Final boss thinker started")
  center = Entities:FindByName(nil, "final_boss_spawn"):GetAbsOrigin()

  -- Wave spawning constants
  local rate = 0.25
  local waveRate = 6

  local deathWaves = 4
  local deathWaveRate = 2.5

  -- HP constants, Min hp = 10, Max hp = 14
  local numPlayers = #Players
  local minPlayers = 4
  local maxPlayers = 8
  local minHp = 10

  numPlayers = math.max(numPlayers, minPlayers)
  numPlayers = math.min(numPlayers, maxPlayers)
  local maxHp = minHp + numPlayers - minPlayers

  -- Movement constants
  local bossMsMin = 325
  local bossMsMax = 525
  local bossPauseMin = 0.75
  local bossPauseMax = 1.55
  local bossRadMin = 400
  local bossRadMax = 700

  -- Wave function names
  local waveNames = {
    "SpawnBarrage",
    "SpawnRapidWide",
    "SpawnTarget",
    "SpawnRapid",
  }
  local currentWaves = {"SpawnFull"}

  local bossSpawn = center + RandomVector(bossRadMin)

  boss = CreateUnitByName("npc_final_boss", bossSpawn, true, nil, nil, DOTA_TEAM_ZOMBIES)
  boss:SetBaseMoveSpeed(bossMsMin)
  boss:SetMaxHealth(maxHp)
  boss:SetHealth(maxHp)
  boss.hp = maxHp

  boss.goal = bossSpawn
  boss.pausing = false

  print("Sending initial final boss net table")
  CustomNetTables:SetTableValue("final_boss", "data", {hp=maxHp, max=maxHp})

  SpawnPatrols()
  SpawnTombstones()

  -- Setting mana to 0
  for _,hero in pairs(Players) do
    hero:SetMana(0)
  end

  -- Starting thinker for boss
  local c = 0
  Timers:CreateTimer(1, function()
    if IsValidEntity(boss) then
      local currentHp = boss:GetHealth()

      -- Spawning a wave
      if math.mod(c, waveRate) == 0 then
        -- Randomly choosing a wave type
        local wave = GetRandomTableElement(currentWaves)
        Waves[wave](self, currentHp, maxHp)
      end

      -- Functions to run when boss gets damaged
      if currentHp < boss.hp then 
        CustomNetTables:SetTableValue("final_boss", "data", {hp=currentHp, max=maxHp})
        IncreasePatrolSpeed(currentHp, maxHp)
        boss.hp = currentHp

        -- Adding more waves to current
        if TableLength(waveNames) > 0 then
          local nextWave = table.remove(waveNames, 1)
          table.insert(currentWaves, nextWave)

          print(nextWave, TableLength(waveNames))
        end
      end

      -- Moving around 
      if not boss.pausing then
        if CalcDist2D(boss:GetAbsOrigin(), boss.goal) < 5 then
          boss.pausing = true

          local bossPause = RandomFloat(bossPauseMin, bossPauseMax)
          local bossMs = RandomFloat(bossMsMin, bossMsMax)
          local bossRad = RandomFloat(bossRadMin, bossRadMax)
          Timers:CreateTimer(bossPause, function()
            local newGoal = RandomVector(bossRad) + center
            boss:SetBaseMoveSpeed(bossMs)
            boss:MoveToPosition(newGoal)
            boss.goal = newGoal
            boss.pausing = false
          end)
        else
          boss:MoveToPosition(boss.goal)
        end
      end

      -- Dealing with death immediately, else for post death animation
      if currentHp == 0 then
        for i = 1,deathWaves do
          Timers:CreateTimer(deathWaveRate*i, function()
            local wave = GetRandomTableElement(waveNames)
            Waves[wave](self, 0, maxHp)
          end)
        end
        --EmitSoundOnLocationWithCaster(center, "Hero_Undying.Death", tombstoneTable[1]) 
        
        return deathWaves*deathWaveRate
      end

      c = c + rate
      return rate
    else
      DestroyTombstones()
      CustomNetTables:SetTableValue("final_boss", "data", {hp=0, max=maxHp})
      return
    end
  end)
end

-- These functions are for spawning waves
function Waves:SpawnFull(hp, maxHp)
  local weight = (maxHp - hp)/maxHp

  local unitsTable = {}

  -- Constants to balance
  local unitsMin = 16
  local unitsMax = 30
  local msMin = 350
  local msMax = 650

  local offset = RandomFloat(0, 90)

  -- Spawning all units first
  local units = RandomWeightedInt(unitsMin, unitsMax, weight)
  local ms = RandomWeightedInt(msMin, msMax, weight)

  --print("Units: ", units, "/", unitsMax, " ms: ", ms, "/", msMax)

  for i = 1,units do
    local angle = math.rad((i/units) * 360 + offset)
    local goal = Vector(center.x + r2*math.cos(angle), center.y + r2*math.sin(angle), 128)

    local unit = Patrols:Initialize({
      name = "npc_creep_patrol_torso", 
      spawn = center,
      goal = goal,
      ms = ms,
      phased = true
    })

    table.insert(unitsTable, unit)
  end

  Timers:CreateTimer(0.2, function()
    for _,unit in pairs(unitsTable) do
      Patrols:MoveToGoalAndDie(unit)
    end
    return
  end)
end

function Waves:SpawnRapid(hp, maxHp)
  local weight = (maxHp - hp)/maxHp

  -- Constants to balance
  local durationMin = 2
  local durationMax = 3.5
  local rateMin = 0.05
  local rateMax = 0.10
  local spacingMin = 8   -- In angles (degrees)
  local spacingMax = 15
  local msMin = 400
  local msMax = 575

  local startAngle = RandomFloat(0, 360)

  -- Generating random values
  local duration = RandomWeightedFloat(durationMin, durationMax, weight)
  local rate = RandomWeightedFloat(rateMin, rateMax, 1 - weight) --Reverse
  local spacing = RandomFloat(spacingMin, spacingMax)
  local ms = RandomWeightedInt(msMin, msMax, weight)

  --print("Rate: ", rateMin, "-", rate, "/", rateMax)
  --print("Spacing: ", spacingMin, "-", spacing, "/", spacingMax)
  --print("Ms: ", msMin, "-", ms, "/", msMax)

  local c = 0
  Timers:CreateTimer(0.1, function()

    local angle = math.rad(startAngle + c*spacing)
    local goal = Vector(center.x + r2*math.cos(angle), center.y + r2*math.sin(angle), 128)

    local unit = Patrols:Initialize({
      name = "npc_creep_patrol_torso", 
      spawn = center,
      goal = goal,
      ms = ms,
      phased = true
    })
    Timers:CreateTimer(0.2, function()
      Patrols:MoveToGoalAndDie(unit)
    end)

    c = c + 1
    -- Duration over
    if (c * rate) > duration then
      return
    end

    return rate
  end)
end

function Waves:SpawnRapidWide(hp, maxHp)
  local weight = (maxHp - hp)/maxHp

  -- Constants to balance
  local durationMin = 2.75
  local durationMax = 3.75
  local rateMin = 0.03
  local rateMax = 0.10
  local spacingMin = 60   -- In angles (degrees)
  local spacingMax = 90
  local msMin = 400
  local msMax = 575

  local startAngle = RandomFloat(0, 360)

  -- Generating random values
  local duration = RandomWeightedFloat(durationMin, durationMax, weight)
  local rate = RandomWeightedFloat(rateMin, rateMax, 1 - weight) --Reverse
  local spacing = RandomFloat(spacingMin, spacingMax)
  local ms = RandomWeightedInt(msMin, msMax, weight)

  --print("Rate: ", rateMin, "-", rate, "/", rateMax)
  --print("Spacing: ", spacingMin, "-", spacing, "/", spacingMax)
  --print("Ms: ", msMin, "-", ms, "/", msMax)

  local c = 0
  Timers:CreateTimer(0.1, function()

    local angle = math.rad(startAngle + c*spacing)
    local goal = Vector(center.x + r2*math.cos(angle), center.y + r2*math.sin(angle), 128)

    local unit = Patrols:Initialize({
      name = "npc_creep_patrol_torso", 
      spawn = center,
      goal = goal,
      ms = ms,
      phased = true
    })
    Timers:CreateTimer(0.2, function()
      Patrols:MoveToGoalAndDie(unit)
    end)

    c = c + 1
    -- Duration over
    if (c * rate) > duration then
      return
    end

    return rate
  end)
end

function Waves:SpawnBarrage(hp, maxHp)
  local weight = (maxHp - hp)/maxHp

  local unitsMin = 8
  local unitsMax = 30
  local spreadMin = 45
  local spreadMax = 75
  local delay = 0.03

  local msMin = 225
  local msMax = 525

  -- Generating random values
  local units = RandomWeightedFloat(unitsMin, unitsMax, weight)
  local spread = RandomWeightedFloat(spreadMin, spreadMax, 1 - weight)

  Timers:CreateTimer(0.1, function()
    local angle = RandomFloat(0, 360)

    for i = 1,units do
      Timers:CreateTimer(i*delay, function()
        local deviation = RandomFloat(-spread/2, spread/2)
        local ms = RandomFloat(msMin, msMax)

        local newAngle = math.rad(angle + deviation)
        local goal = Vector(center.x + r2*math.cos(newAngle), center.y + r2*math.sin(newAngle), 128) 

        local unit = Patrols:Initialize({
          name = "npc_creep_patrol_torso", 
          spawn = center,
          goal = goal,
          ms = ms,
          phased = true
        })
        Patrols:MoveToGoalAndDie(unit)
      end)
    end
  end)
end

function Waves:SpawnTarget(hp, maxHp)
  local weight = (maxHp - hp)/maxHp

  local ms = 800
  local unitsMin = 8
  local unitsMax = 20
  local chanceMin = 0.40
  local chanceMax = 0.75
  local rate = 0.1

  -- Generate random
  local units = RandomWeightedFloat(unitsMin, unitsMax, weight)
  local chance = RandomWeightedFloat(chanceMin, chanceMax, weight)

  for i = 1,units do
    Timers:CreateTimer(i*rate, function()
      local roll = RandomFloat(0, 1)

      local targets = FindUnitsInRadius(DOTA_TEAM_GOODGUYS,
        center, 
        nil, 
        r2, 
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
        DOTA_UNIT_TARGET_ALL, 
        DOTA_UNIT_TARGET_FLAG_NONE, 
        FIND_ANY_ORDER, 
        false
      )

      local angle

      if (#targets == 0) or (roll > chance) then
        angle = math.rad(RandomFloat(0, 360))
      else
        local randTarget = GetRandomTableElement(targets)
        local posTarget = randTarget:GetAbsOrigin()
        angle = math.atan((posTarget.y - center.y)/(posTarget.x - center.x))
      end

      local goal = Vector(center.x + r2*math.cos(angle), center.y + r2*math.sin(angle), 128)

      local unit = Patrols:Initialize({
        name = "npc_creep_patrol_torso", 
        spawn = center,
        goal = goal,
        ms = ms,
        phased = true
      })
      Patrols:MoveToGoalAndDie(unit)
    end)
  end
end

-- This function is for spawning the permanent patrols in the level and speeding them up
function SpawnPatrols()
  print("Spawning patrols around boss")
  local ms = patrolMsStart
  local ringSpacing = 175
  local spacing = 3200
  local moveFactor = 0.75
  local rate = 2

  local rings = math.ceil((r2 - r1)/ringSpacing) 

  for i = 1,rings do
    local r = r1 + ringSpacing*(i-1)
    local perimeter = 2*math.pi*r

    local nUnits = math.ceil(perimeter/spacing)

    for j = 1,nUnits do
      local angle = math.rad(j*(360/nUnits))
      local spawn = Vector(center.x + r*math.cos(angle), center.y + r*math.sin(angle), 128)
      local unit = CreateUnitByName("npc_creep_patrol_no_turn", spawn, true, nil, nil, DOTA_TEAM_ZOMBIES)
      unit:SetBaseMoveSpeed(ms)
      unit.ms = ms
      unit.angle = angle
      unit.r = r
      unit.spawn = spawn
      unit.opposite = 1

      -- Alternating rotation
      if math.mod(i,2) == 0 then
        unit.opposite = -1
      end

      table.insert(patrolsTable, unit)
    end
  end

  local c = 0
  Timers:CreateTimer(0.5, function()
    if GameRules.CLevel == 6 then
      for _,unit in pairs(patrolsTable) do
        local r = unit.r
        local angleMove = (unit.ms * rate / r) * unit.opposite
        local angleNew = unit.angle + angleMove * moveFactor
        local pos = Vector(center.x + r*math.cos(angleNew), center.y + r*math.sin(angleNew), 128)

        unit:MoveToPosition(pos)
        unit.angle = angleNew
      end

      c = c + 1
      return rate
    else
      return
    end
  end)
end

function IncreasePatrolSpeed(hp, maxHp)
  print("Speeding up patrols")
  local maxMs = 550
  local newMs = MapValue(hp, maxHp, 0, patrolMsStart, maxMs)
  newMs = math.floor(newMs + 0.5)
  print(newMs)

  for _,unit in pairs(patrolsTable) do
    unit.ms = newMs
    unit:SetBaseMoveSpeed(newMs)

    if RandomInt(0, 2) == 0 then
      local part = ParticleManager:CreateParticle("particles/items4_fx/bull_whip.vpcf", PATTACH_ABSORIGIN, boss)
      ParticleManager:SetParticleControl(part, 0, boss:GetAbsOrigin())
      ParticleManager:SetParticleControl(part, 1, unit:GetAbsOrigin())
    end
  end
  EmitSoundOnLocationWithCaster(center, "Item.Bullwhip.Ally", boss)
end

-- This function spawns/destroys the blocking tombstones
function SpawnTombstones()
  print("Spawning tombstones")
  local hullRadius = 100
  local exit = Entities:FindByName(nil, "exit6"):GetAbsOrigin()

  local centerTomb = CreateUnitByName("npc_tombstone", center, true, nil, nil, DOTA_TEAM_ZOMBIES)
  local exitTomb = CreateUnitByName("npc_tombstone", exit, true, nil, nil, DOTA_TEAM_ZOMBIES)
  
  centerTomb:SetHullRadius(hullRadius)
  centerTomb:SetForwardVector(Vector(0, -1, 0))
  centerTomb:AddNewModifier(centerTomb, nil, "modifier_invulnerable", {})

  exitTomb:SetHullRadius(hullRadius)
  exitTomb:SetForwardVector(Vector(0, -1, 0))

  table.insert(tombstoneTable, centerTomb)
  table.insert(tombstoneTable, exitTomb)

  EmitSoundOnLocationWithCaster(center, "Hero_Undying.Tombstone", centerTomb) 
end

function DestroyTombstones()
  print("Destroying tombstones")
  for _,tombstone in pairs(tombstoneTable) do
    tombstone:ForceKill(true)
  end
end

-- This functiion is for the mango spawning for final boss
function barebones:MangoThinker()
  print("Final boss mango thinker started")
  local mango

  local r1m = r1
  local r2m = r2 * (2/3)
  local angle1 = -45
  local angle2 = 225

  Timers:CreateTimer(1, function()
    --print(IsValidEntity(mango))
    local totalMana = 0
    for _,hero in pairs(Players) do
      totalMana = totalMana + hero:GetMana()
    end

    if GameRules.CLevel == 6 then
      if IsValidEntity(mango) or totalMana > 0 then
        -- Emit indicator
        local pos
        if totalMana > 0 then
          for _,hero in pairs(Players) do
            if hero:GetMana() > 0 then
              pos = hero:GetAbsOrigin()
            end
          end
        else
          local container = mango:GetContainer()
          if mango:GetContainer() then
            pos = container:GetAbsOrigin()
          else
            pos = mango:GetAbsOrigin()
          end
        end

        if not mango.emitted then
          local part = ParticleManager:CreateParticle("particles/misc/ring_emitter.vpcf", PATTACH_ABSORIGIN, boss)
          ParticleManager:SetParticleControl(part, 0, pos)
          mango.emitted = true

          Timers:CreateTimer(5, function()
            mango.emitted = false
          end)
        end
      else
        -- Spawn mango
        local angle = math.rad(RandomFloat(angle1, angle2))
        local r = RandomFloat(r1m, r2m)
        local pos = Vector(center.x + r*math.cos(angle), center.y + r*math.sin(angle), 128)

        mango = CreateItem("item_mango_custom_self", nil, nil)
        mango.spawn = pos
        mango.respawn = false
        mango.emitted = false
        CreateItemOnPositionSync(pos, mango) 
      end
      return 1.5
    else
      return
    end
  end)
end