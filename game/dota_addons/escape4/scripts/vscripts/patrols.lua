Patrols = Patrols or {}

function Patrols:Initialize(dataTable)
  local unitName = dataTable.name
  local spawn = dataTable.spawn
  local goal = dataTable.goal
  local ms = dataTable.ms and dataTable.ms or 300

  local showParticle = true  -- Show by default

  if dataTable.showParticle ~= nil then
    showParticle = dataTable.showParticle
  end

  local unit = CreateUnitByName(unitName, spawn, false, nil, nil, DOTA_TEAM_ZOMBIES)
  unit:SetBaseMoveSpeed(ms)
  unit:SetForwardVector(goal - spawn)
  unit.goal = goal

  if dataTable.phased then
    Timers:CreateTimer(function()
      unit:AddNewModifier(unit, nil, "modifier_spectre_spectral_dagger_path_phased", {})
    end)
  end 

  if showParticle then
    Timers:CreateTimer(function()
      unit:AddNewModifier(unit, nil, "modifier_item_phase_boots_active", {})
    end)
  end

  if ms > 550 then
    unit:AddNewModifier(unit, nil, "modifier_bloodseeker_thirst", {})
    unit:AddNewModifier(unit, nil, "modifier_bloodseeker_thirst_speed", {})
  end

  unit:FindAbilityByName("patrol_unit_passive"):SetLevel(1)

  return unit
end

function Patrols:MoveToGoalAndDie(unit)
  Timers:CreateTimer(0.03, function()
    if IsValidEntity(unit) then
      if CalcDist2D(unit:GetAbsOrigin(), unit.goal) < 10 then
        -- Directly removing carty, messy death animation
        if unit:GetUnitName() == "npc_carty" then
          unit:RemoveSelf()
          return
        end
        unit:ForceKill(true)
        return
      else
        unit:MoveToPosition(unit.goal)
        return 0.25
      end 
    else
      if not unit:IsNull() then
        unit:RemoveSelf()
      end
      return
    end
  end)
end  