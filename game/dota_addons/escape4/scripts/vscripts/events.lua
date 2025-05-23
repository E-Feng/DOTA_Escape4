-- This file contains all barebones-registered events and has already set up the passed-in parameters for you to use.
-- You should comment or remove the stuff you don't need

-- Handle stuff when a player disconnects
function barebones:OnDisconnect(keys)
	DebugPrint("[BAREBONES] A Player has disconnected ".. tostring(keys.userid))
	--PrintTable(keys)

	local name = keys.name
	local networkID = keys.networkid
	local reason = keys.reason
	local userID = keys.userid
	local playerID = keys.PlayerID
end

-- The overall game state has changed
function barebones:OnGameRulesStateChange(keys)
	--PrintTable(keys)

	local new_state = GameRules:State_Get()

	if new_state == DOTA_GAMERULES_STATE_INIT then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_INIT")

	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD")

	elseif new_state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP")
		GameRules:SetCustomGameSetupAutoLaunchDelay(CUSTOM_GAME_SETUP_TIME)

	elseif new_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_HERO_SELECTION")
		self:PostLoadPrecache()
		self:OnAllPlayersLoaded()
	elseif new_state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_STRATEGY_TIME")

	elseif new_state == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_TEAM_SHOWCASE")

	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_MAP_TO_LOAD then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_WAIT_FOR_MAP_TO_LOAD")

	elseif new_state == DOTA_GAMERULES_STATE_PRE_GAME then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_PRE_GAME")

	elseif new_state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_GAME_IN_PROGRESS")
		self:OnGameInProgress()

	elseif new_state == DOTA_GAMERULES_STATE_POST_GAME then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_POST_GAME")

	elseif new_state == DOTA_GAMERULES_STATE_DISCONNECT then
		DebugPrint("[BAREBONES] Game State changed to: DOTA_GAMERULES_STATE_DISCONNECT")

	end
end

-- An NPC has spawned somewhere in game. This includes heroes
function barebones:OnNPCSpawned(keys)
	DebugPrint("[BAREBONES] A unit Spawned")
	--PrintTable(keys)

	local npc = EntIndexToHScript(keys.entindex)
	local unit_owner = npc:GetOwner()

	-- Put things here that will happen for every unit or hero when they spawn

	-- OnHeroInGame
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		local hero = npc

		hero.id = hero:GetPlayerID()
		if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			Players[hero.id] = hero
			--barebones:SetPlayerColor(hero)
			print("----------Player insertion into table----------")
			print("Player Id (", hero.id, ") inserted into table")
			print("Table is now length ", TableLength(Players))
			print("----------Player insertion finished----------")

			local color = TeamColors[hero.id]
			if color == nil then
				color = {255, 255, 255} -- white
			end
			PlayerResource:SetCustomPlayerColor(hero.id, color[1], color[2], color[3])
		end

		self:OnHeroInGame(npc)
	end
end

--[[
  Hero spawned for the first time. It can happen if the player's hero is replaced with a new hero for any reason.  
  This can be used for initializing heroes, such as adding levels, changing the starting gold, removing/adding abilities, adding physics, etc.
  This happens to bot and custom created heroes as well.
  The hero parameter is the hero entity that just spawned.
  
]]
function barebones:OnHeroInGame(hero)
		-- Initializing hero parameters
		local modelRad = hero:GetModelRadius()
		local reviveRad = math.max(modelRad, REVIVE_RAD_MIN)
		local scaledRad = math.pow(reviveRad, 0.6) * 7 + (REVIVE_RAD_MIN - math.pow(REVIVE_RAD_MIN, 0.6) * 7)
		--print("Radius for reviving", modelRad, scaledRad)

		hero.isSafe = true

		hero.patreonLevel = 0
		hero.beaconSize = BEACON_NORMAL    -- Normal:84   Large:120 for patreon item
		hero.reviveRadius = scaledRad
		hero.largerXMod = false
		hero.phaseMod = false

		hero.outOfBoundsDeath = false
		hero.mana = 0
		hero.hookZ = 0


	Timers:CreateTimer(0.5, function()
		local playerID = hero:GetPlayerID()	-- never nil (-1 by default), needs delay 1 or more frames

		-- Initializing hero with proper skills 
		local setVisible = not GIVE_ALL_SPELLS
		local setImmoLevel = GIVE_IMMO_SPELL and 1 or 0

		-- hero:SetBaseMagicalResistanceValue(25)	
		hero:SetAbilityPoints(0)
		hero:SetMana(0)

		-- Clearing all abilities and adding
		for i = 0,16 do
			local abil = hero:GetAbilityByIndex(i)
			if abil then
				hero:RemoveAbility(abil:GetAbilityName())
			end
		end

		-- Adding the empty abilities
		if setVisible then
			for i = 1,6 do
				hero:AddAbility("barebones_empty" .. i)
			end
		end

		for _,abilName in pairs(_G.abilList) do
			local addedAbil = hero:AddAbility(abilName)
			addedAbil:SetHidden(setVisible)
			addedAbil:SetLevel(1)
		end

		-- hero:AddAbility("self_immolation"):SetLevel(setImmoLevel)
		hero:AddAbility("self_immolation_lua"):SetLevel(setImmoLevel)

		-- Adding items to inventory
		hero:AddItemByName("item_boots")
		hero:AddItemByName("item_patreon_get_cheese1")
		hero:AddItemByName("item_patreon_chest")

		if tostring(PlayerResource:GetSteamID(0)) == "76561197965802278" then
			hero:AddItemByName("item_blink_custom")
		end
		
		if GIVE_BLINK then
			hero:AddItemByName("item_blink_custom")
		end

		--hero:AddItemByName("item_patreon_larger_x")
		--hero:AddItemByName("item_patreon_wind_lace")
		--hero:AddItemByName("item_patreon_phoenix_ash")
		--hero:AddItemByName("item_patreon_phase")

		-- Removing random items
		Timers:CreateTimer(1, function()
			local mango = hero:FindItemInInventory("item_enchanted_mango")
			local faerie = hero:FindItemInInventory("item_faerie_fire")

			if mango ~= nil then
				if mango:GetContainer() ~= nil then
					mango:GetContainer():RemoveSelf()
				end
				mango:RemoveSelf()
			end

			if faerie ~= nil then
				if faerie:GetContainer() ~= nil then
					faerie:GetContainer():RemoveSelf()
				end
				faerie:RemoveSelf()
			end			
		end)


		-- Setting respawn if using debug
		if USE_LEVEL_DEBUG and TableLength(Players) == 1 then
			local spawn = Entities:FindByName(nil, "checkpoint" .. tostring(LEVEL_DEBUG)):GetAbsOrigin()
			GameRules.Checkpoint = spawn

			hero:SetRespawnPosition(spawn)
			hero:SetAbsOrigin(spawn)
		end


		-- Barebones code
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots
			DebugPrint("[BAREBONES] Bot hero "..hero:GetUnitName().." (re)spawned in the game.")
			-- Set starting gold for bots
			hero:SetGold(NORMAL_START_GOLD, false)
			--hero:AddItemByName("item_boots")
		else
			DebugPrint("[BAREBONES] OnHeroInGame running for a non-bot player!")
			if not PlayerResource.PlayerData[playerID] then
				PlayerResource.PlayerData[playerID] = {}
				DebugPrint("[BAREBONES] PlayerResource's PlayerData for playerID "..playerID.." was not properly initialized.")
			end
			if hero:IsClone() then
				DebugPrint("[BAREBONES] Spawned hero is a clone (for example: meepo clone or monkey king ult clone)")
			end
			-- Set some hero stuff on first spawn or on every spawn (custom or not)
			if PlayerResource.PlayerData[playerID].already_set_hero == true then
				-- This is happening only when players create new heroes with custom hero-create spells:
				-- Custom Illusion spells
			else
				-- This is happening for players when their primary hero spawns for the first time
				DebugPrint("[BAREBONES] Hero "..hero:GetUnitName().." spawned in the game for the first time for the player with ID "..playerID)

				-- Make heroes briefly visible on spawn (to prevent bad fog of war interactions)
				hero:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.5)
				hero:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.5)

				-- Set the starting gold for the player's hero
				-- If the NORMAL_START_GOLD is smaller then 600, remove Strategy Time and use SetGold
				--PlayerResource:ModifyGold(playerID, NORMAL_START_GOLD-600, false, 0)

				-- Create an item and add it to the player, effectively ensuring they start with the item
				if ADD_ITEM_TO_HERO_ON_SPAWN then
					--hero:AddItemByName("item_boots")
				end

				-- Make sure that stuff above will not happen again for the player if some other hero spawns
				-- for him for the first time during the game 
				PlayerResource.PlayerData[playerID].already_set_hero = true
				DebugPrint("[BAREBONES] Hero "..hero:GetUnitName().." set for the player with ID "..playerID)
			end
		end
	end)
end

-- An item was picked up off the ground
function barebones:OnItemPickedUp(keys)
	DebugPrint("[BAREBONES] OnItemPickedUp")
	--PrintTable(keys)

	-- Find who picked up the item
	local unit_entity
	if keys.UnitEntitIndex then -- keys.UnitEntitIndex may be always nil
		unit_entity = EntIndexToHScript(keys.UnitEntitIndex)
	elseif keys.HeroEntityIndex then
		unit_entity = EntIndexToHScript(keys.HeroEntityIndex)
	end

	local item_entity = EntIndexToHScript(keys.ItemEntityIndex)
	local playerID = keys.PlayerID
	local item_name = keys.itemname
end

-- A player has reconnected to the game. This function can be used to repaint Player-based particles or change state as necessary
function barebones:OnPlayerReconnect(keys)
	DebugPrint("[BAREBONES] A Player has reconnected.")
	--PrintTable(keys)

	local new_state = GameRules:State_Get()
	if new_state > DOTA_GAMERULES_STATE_HERO_SELECTION then
		local playerID = keys.PlayerID or keys.player_id

		if PlayerResource:HasSelectedHero(playerID) or PlayerResource:HasRandomed(playerID) then
			-- This playerID already had a hero before disconnect
		else
			-- PlayerResource:IsConnected(index) is custom-made; can be found in 'player_resource.lua' library
			if PlayerResource:IsConnected(playerID) and (not PlayerResource:IsBroadcaster(playerID)) then
				PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
				PlayerResource:SetHasRandomed(playerID)
				PlayerResource:SetCanRepick(playerID, false)
				DebugPrint("[BAREBONES] Randomed a hero for a player number "..playerID.." that reconnected.")
			end
		end
	end
end

-- An ability was used by a player
function barebones:OnAbilityUsed(keys)
	--PrintTable(keys)
	--print("Ability used by player")

	local playerID = keys.PlayerID
	local ability_name = keys.abilityname
	local caster = keys.caster_entindex

	--local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
	local hero = EntIndexToHScript(caster)


	if ability_name == "invoker_sun_strike_custom" then
		local playerName = PlayerResource:GetPlayerName(playerID)

		hero.sunstrikesCasted = hero.sunstrikesCasted or 0
		hero.sunstrikesHit = hero.sunstrikesHit or 0

		hero.sunstrikesCasted = hero.sunstrikesCasted + 1

		local tempHp = _G.BossHp
		local color = "lime"
		local status = " hit!"

		Timers:CreateTimer(2, function()
			if _G.BossHp == tempHp then
				color = "red"
				status = " missed!"
			else
				hero.sunstrikesHit = hero.sunstrikesHit + 1
			end

			local percentage = " (" .. hero.sunstrikesHit .. "/" .. hero.sunstrikesCasted .. ")"
			local str = playerName .. percentage .. status
			local msg = {
				text = str,
				duration = 3.0,
				style={color=color, ["font-size"]="32px"}
			}
			Notifications:TopToAll(msg)
		end)
	elseif ability_name == "rattletrap_hookshot_custom" then
		--print("Z pos after hook: ", hero:GetAbsOrigin().z)
		hero.hookZ = hero:GetAbsOrigin().z
	elseif ability_name == "enchantress_bunny_hop_custom" then
		hero:AddNewModifier(hero, nil, "modifier_stunned", {duration=0.36})
	end

	-- If you need to adjust abilities on their cast, use Order Filter or modifier events, not this
end

-- A player leveled up an ability; Note: IT DOESN'T TRIGGER WHEN YOU USE SetLevel() ON THE ABILITY!
function barebones:OnPlayerLearnedAbility(keys)
	DebugPrint("[BAREBONES] OnPlayerLearnedAbility")
	--PrintTable(keys)

	local player
	if keys.player then
		player = EntIndexToHScript(keys.player)
	end

	local ability_name = keys.abilityname

	local playerID
	if player then
		playerID = player:GetPlayerID()
	else
		playerID = keys.PlayerID
	end

    -- PlayerResource:GetBarebonesAssignedHero(index) is custom-made; can be found in 'player_resource.lua' library
	local hero = PlayerResource:GetBarebonesAssignedHero(playerID)

	-- Handling talents without custom net tables, this is just an example
	local talents = {
		{"special_bonus_unique_chaos_knight", "modifier_reality_rift_talent_1"},
		{"special_bonus_unique_chaos_knight_2", "modifier_reality_rift_talent_2"}
	}

	for i = 1, #talents do
		local talent = talents[i]
		if ability_name == talent[1] then
			local talent_ability = hero:FindAbilityByName(ability_name)
			if talent_ability then
				local talent_modifier = talent[2]
				hero:AddNewModifier(hero, talent_ability, talent_modifier, {})
			end
		end
	end
end

-- A player leveled up
function barebones:OnPlayerLevelUp(keys)
	DebugPrint("[BAREBONES] OnPlayerLevelUp")
	--PrintTable(keys)

	local level = keys.level
	local playerID = keys.player_id or keys.PlayerID -- Valve keep changing this :)

	local hero 
	if keys.hero_entindex then
		hero = EntIndexToHScript(keys.hero_entindex)
	else
		hero = PlayerResource:GetBarebonesAssignedHero(playerID)
	end

	if hero then
		-- Update hero gold bounty when a hero gains a level
		if USE_CUSTOM_HERO_GOLD_BOUNTY then
			local hero_level = hero:GetLevel() or level
			local hero_streak = hero:GetStreak()

			local gold_bounty
			if hero_streak > 2 then
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
			else
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
			end

			--hero:SetMinimumGoldBounty(gold_bounty)
			--hero:SetMaximumGoldBounty(gold_bounty)
			hero:SetMinimumGoldBounty(0)
			hero:SetMaximumGoldBounty(0)
		end

		-- Add a skill point when a hero levels up
		if SKILL_POINTS_AT_EVERY_LEVEL then
			local levels_without_ability_point = {17, 19, 21, 22, 23, 24}	-- on this levels you should get a skill point
			for i = 1, #levels_without_ability_point do
				if level == levels_without_ability_point[i] then
					local unspent_ability_points = hero:GetAbilityPoints()
					hero:SetAbilityPoints(unspent_ability_points+1)
				end
			end
		end

		-- If you want to remove skill points when a hero levels up then uncomment the following line:
		-- hero:SetAbilityPoints(0)
	end
end

-- A player last hit a creep, a tower, or a hero
function barebones:OnLastHit(keys)
	DebugPrint("[BAREBONES] OnLastHit")
	--PrintTable(keys)

	local IsFirstBlood = keys.FirstBlood == 1
	local IsHeroKill = keys.HeroKill == 1
	local IsTowerKill = keys.TowerKill == 1

	-- Player ID that got a last hit
	local playerID = keys.PlayerID

	-- Killed unit (creep, hero, tower etc.)
	local killed_entity = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function barebones:OnTreeCut(keys)
	DebugPrint("[BAREBONES] OnTreeCut")
	--PrintTable(keys)

	-- Tree coordinates on the map
	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function barebones:OnRuneActivated(keys)
	DebugPrint("[BAREBONES] OnRuneActivated")
	--PrintTable(keys)

  local playerID = keys.PlayerID
  local rune = keys.rune

  -- For Bounty Runes use BountyRuneFilter
  -- For modifying which runes spawn use RuneSpawnFilter
  -- This event can be used for adding more effects to existing runes.
end

-- A player picked or randomed a hero (this is happening before OnHeroInGame because OnHeroInGame has a timers delay).
function barebones:OnPlayerPickHero(keys)
	DebugPrint("[BAREBONES] OnPlayerPickHero")
	--PrintTable(keys)

	local hero_name = keys.hero
	local hero_entity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)

	Timers:CreateTimer(0.5, function()
		local playerID = hero_entity:GetPlayerID() -- or player:GetPlayerID() if player is not disconnected
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots when they spawn for the first time or if they use custom hero-create spells (Custom Illusion spells)
		else
			if not PlayerResource.PlayerData[playerID] then
				PlayerResource.PlayerData[playerID] = {}
				DebugPrint("[BAREBONES] PlayerResource's PlayerData for playerID "..playerID.." was not properly initialized.")
			end
			if PlayerResource.PlayerData[playerID].already_assigned_hero == true then
				-- This is happening only when players create new heroes with spells (Custom Illusion spells)
			else
				PlayerResource:AssignHero(playerID, hero_entity)
				PlayerResource.PlayerData[playerID].already_assigned_hero = true
			end
		end
	end)
end

-- An entity died (an entity killed an entity)
function barebones:OnEntityKilled(keys)
    DebugPrint("[BAREBONES] An entity was killed.")
    --PrintTable(keys)

    -- Indexes:
    local killed_entity_index = keys.entindex_killed
    local attacker_entity_index = keys.entindex_attacker
	local inflictor_index = keys.entindex_inflictor -- it can be nil if not killed by an item/ability

    -- Find the entity that was killed
    local killed_unit
    if killed_entity_index then
      killed_unit = EntIndexToHScript(killed_entity_index)
    end

    -- Find the entity (killer) that killed the entity mentioned above
    local killer_unit
    if attacker_entity_index then
      killer_unit = EntIndexToHScript(attacker_entity_index)
    end

	if killed_unit == nil or killer_unit == nil then
      -- don't continue if killer or killed entity dont exist
      return
    end

	-- Find the ability/item used to kill, or nil if not killed by an item/ability
    local killing_ability
    if inflictor_index then
      killing_ability = EntIndexToHScript(inflictor_index)
    end

    -- For Meepo clones, find the original
    if killed_unit:IsClone() then
      if killed_unit:GetCloneSource() then
        killed_unit = killed_unit:GetCloneSource()
      end
    end

	-- Killed Unit is a hero (not an illusion) and he is not reincarnating
	if killed_unit:IsRealHero() and not killed_unit:IsTempestDouble() and not killed_unit:IsReincarnating() then
		-- Hero gold bounty update for the killer
		if USE_CUSTOM_HERO_GOLD_BOUNTY then	
			if killer_unit:IsRealHero() then
				-- Get his killing streak
				local hero_streak = killer_unit:GetStreak()
				-- Get his level
				local hero_level = killer_unit:GetLevel()
				-- Adjust Gold bounty
				local gold_bounty
				if hero_streak > 2 then
					gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
				else
					gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
				end
			
				killer_unit:SetMinimumGoldBounty(gold_bounty)
				killer_unit:SetMaximumGoldBounty(gold_bounty)
			end
		end

		-- Hero Respawn time configuration
		if ENABLE_HERO_RESPAWN then
			local killed_unit_level = killed_unit:GetLevel()

			-- Calculating respawn time without buyback penalty
			local respawn_time = 1
			if USE_CUSTOM_RESPAWN_TIMES then
				-- Get respawn time from the table that we defined
				respawn_time = CUSTOM_RESPAWN_TIME[killed_unit_level]
			else
				-- Get dota default respawn time
				respawn_time = killed_unit:GetRespawnTime()
			end

			-- Fixing respawn time after level 30, this is usually bugged in custom games if default respawn times are used -> respawn time are either too long or too short. We fix that.
			local respawn_time_after_30 = 100 + (killed_unit_level-30)*5
			if killed_unit_level > 30 and respawn_time ~= respawn_time_after_30 and not USE_CUSTOM_RESPAWN_TIMES then
				respawn_time = respawn_time_after_30
			end

			-- Old Bloodstone respawn reduction (this example doesn't check items in backpack because bloodstone cannot go in backpack)
			-- for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
				-- local item = killed_unit:GetItemInSlot(i)
				-- if item then
					-- if item:GetName() == "item_bloodstone" then
						-- local current_charges = item:GetCurrentCharges()
						-- local charges_before_death = math.ceil(current_charges*1.5)
						-- local reduction_per_charge = item:GetLevelSpecialValueFor("respawn_time_reduction", item:GetLevel() - 1)
						-- local respawn_reduction = charges_before_death*reduction_per_charge
						-- respawn_time = math.max(1, respawn_time-respawn_reduction)
						-- break -- break for loop, to prevent multiple bloodstones granting respawn reduction
					-- end
				-- end
			-- end

			-- Reaper's Scythe respawn time increase
			if killing_ability then
				if killing_ability:GetAbilityName() == "necrolyte_reapers_scythe" then
					DebugPrint("[BAREBONES] A hero was killed by a Necro Reaper's Scythe. Increasing respawn time!")
					local respawn_extra_time = killing_ability:GetLevelSpecialValueFor("respawn_constant", killing_ability:GetLevel() - 1)
					respawn_time = respawn_time + respawn_extra_time
				end
			end

			-- Killer is a neutral creep
			if killer_unit:IsNeutralUnitType() then
				-- If a hero is killed by a neutral creep, respawn time can be modified here
			end

			-- Capping Respawn Time (MAX respawn time)
			if respawn_time > MAX_RESPAWN_TIME then
				DebugPrint("[BAREBONES] Reducing respawn time of "..killed_unit:GetUnitName().." because it was too long.")
				respawn_time = MAX_RESPAWN_TIME
			end
			
			-- If hero is actually reincarnating don't change his respawn time:
			if not killed_unit:IsReincarnating() then
				killed_unit:SetTimeUntilRespawn(respawn_time)
			end
		end

		-- Hero Buyback Cooldown
		if CUSTOM_BUYBACK_COOLDOWN_ENABLED then
			PlayerResource:SetCustomBuybackCooldown(killed_unit:GetPlayerID(), CUSTOM_BUYBACK_COOLDOWN_TIME)
		end

		-- Buyback Fixed Gold Cost
		if CUSTOM_BUYBACK_COST_ENABLED then
			PlayerResource:SetCustomBuybackCost(killed_unit:GetPlayerID(), BUYBACK_FIXED_GOLD_COST)
		end

		-- Killer is not a real hero but it killed a hero
		if killer_unit:IsTower() or killer_unit:IsCreep() or killer_unit:IsFountain() then
			-- Put stuff here that you want to happen if a hero is killed by a creep, tower or fountain.
		end

		-- When team hero kill limit is reached declare the winner
		if END_GAME_ON_KILLS and GetTeamHeroKills(killer_unit:GetTeam()) >= KILLS_TO_END_GAME_FOR_TEAM then
			GameRules:SetGameWinner(killer_unit:GetTeam())
		end

		-- Setting top bar values
		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS))
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
		end
	end

	-- Ancient destruction detection (if the map doesn't have ancients with these names, this will never happen)
	if killed_unit:GetUnitName() == "npc_dota_badguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
		GameRules:SetCustomVictoryMessage("#dota_post_game_radiant_victory")
		GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
	elseif killed_unit:GetUnitName() == "npc_dota_goodguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
		GameRules:SetCustomVictoryMessage("#dota_post_game_dire_victory")
		GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
	end

	-- Remove dead non-hero units from selection -> fixing bugged ability/cast bar
	if killed_unit:IsIllusion() or (killed_unit:IsControllableByAnyPlayer() and not killed_unit:IsRealHero() and not killed_unit:IsCourier() and not killed_unit:IsClone() and not killed_unit:IsTempestDouble()) then
		local player = killed_unit:GetPlayerOwner()
		local playerID
		if player == nil then
			playerID = killed_unit:GetPlayerOwnerID()
		else
			playerID = player:GetPlayerID()
		end
		
		if Selection then
			-- Without Selection library this will return an error
			PlayerResource:RemoveFromSelection(playerID, killed_unit)
		end
	end

	-- Calls HeroKilled function if hero is killed
	if killed_unit:IsRealHero() then
		DebugPrint("[BAREBONES] Hero killed, calling HeroKilled function")
		barebones:HeroKilled(killed_unit, killer_unit, killing_ability)
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function barebones:OnConnectFull(keys)
	DebugPrint("[BAREBONES] A Player fully connected.")
	--PrintTable(keys)

	self:CaptureGameMode()

	local index = keys.index           -- player slot
	local playerID = keys.PlayerID
	local userID = keys.userid         -- user ID on server

	-- PlayerResource:OnPlayerConnect(event) is custom-made; can be found in 'player_resource.lua' library
	PlayerResource:OnPlayerConnect(keys)
end

-- This function is called whenever a tower is destroyed
function barebones:OnTowerKill(keys)
	DebugPrint("[BAREBONES] OnTowerKill")
	--PrintTable(keys)

	local gold = keys.gold
	local killer_userID = keys.killer_userid
	local team = keys.teamnumber
end

-- This function is called whenever a player changes their custom team selection during Custom Game Setup 
function barebones:OnPlayerSelectedCustomTeam(keys)
	DebugPrint("[BAREBONES] OnPlayerSelectedCustomTeam")
	--PrintTable(keys)

	local playerID = keys.player_id
	local success = (keys.success == 1)
	local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target (npc can be a lane creep, goal entity can be a path corner)
function barebones:OnNPCGoalReached(keys)
	DebugPrint("[BAREBONES] OnNPCGoalReached")
	--PrintTable(keys)

	local goal_entity_index = keys.goal_entindex             -- Entity index of the next goal entity on the path (if any) which the npc will now be pathing towards
	local next_goal_entity_index = keys.next_goal_entindex   -- Entity index of the path goal entity which has been reached
	local npc_index = keys.npc_entindex                      -- Entity index of the npc which was following a path and has reached a goal entity

	local npc
	local goal_entity

	if npc_index and goal_entity_index then
		npc = EntIndexToHScript(npc_index)
		goal_entity = EntIndexToHScript(goal_entity_index)
	end

	local next_goal_entity
	if next_goal_entity_index then
		next_goal_entity = EntIndexToHScript(next_goal_entity_index)
	end

	if npc and goal_entity then
		-- Your code here
	end
end

-- This function is called whenever any player sends a chat message to team or to All
function barebones:OnPlayerChat(keys)
	DebugPrint("[BAREBONES] Player used the chat")
	--PrintTable(keys)

	local team_only = keys.teamonly -- true if team only chat
	local userID = keys.userid
	local playerID = keys.playerid
	local text = keys.text

	local numPlayers

	if text == "-votekill" then
		if not GameRules.VoteOngoing then
			print("Kill all vote started")
			GameRules.VoteOngoing = true
			Vote = {}
			numPlayers = 0
			for i,hero in pairs(Players) do
				if PlayerResource:IsConnected(i) then
					numPlayers = numPlayers + 1
				end
			end
			votesNeeded = math.max(math.floor(numPlayers/2) + 1, 2) -- Min of 2 votes
			print("Num players and num votes", numPlayers, votesNeeded)

			local name = PlayerResource:GetPlayerName(playerID)
			name = string.sub(name, 1, 15)
			local init_msg = {
				text = name .. " started kill all vote, need " .. tostring(votesNeeded) .. " to succeed. <br/>Type '-votekill' to vote.",
				duration = 8.0,
				style = {color="red", ["font-size"]="60px"}
			}
			Notifications:TopToAll(init_msg)
			table.insert(Vote, playerID)
			Timers:CreateTimer(30, function()
				if GameRules.VoteOngoing == true then
					print("Vote failed")
					GameRules.VoteOngoing = false
					Vote = {}
					local fail_msg = {
						text = "Vote has failed, type '-votekill' to try again.",
						duration = 4.0,
						style = {color="red", ["font-size"]="60px"}
					}
					Notifications:TopToAll(fail_msg)
				end
			end)
		else
			--playerID = RandomInt(0, 9)
			if not TableContains(Vote, playerID) and #Vote > 0 then
				print("Player ID ", playerID, " has voted")
				table.insert(Vote, playerID)
				local name = PlayerResource:GetPlayerName(playerID)
				name = string.sub(name, 1, 15)
				local numVotes = #Vote
				local vote_msg = {
					text = name .. " voted: " .. tostring(numVotes) .. "/" .. tostring(votesNeeded),
					duration = 4.0,
					style = {color="red", ["font-size"]="60px"}
				}
				Notifications:TopToAll(vote_msg)
				if numVotes >= votesNeeded then
					print("Vote passed, killing all")
					Vote = {}	
					local success_msg = {
						text = "Vote successful, killing all",
						duration = 4.0,
						style = {color="red", ["font-size"]="60px"}
					}
					Notifications:TopToAll(success_msg)			
					Timers:CreateTimer(4, function()	
						GameRules.VoteOngoing = false
						for i,hero in pairs(Players) do
							if hero:IsAlive() then
								hero:SetBaseMagicalResistanceValue(25)
							end
						end
					end)
				end
			end
		end
	elseif string.sub(text, 1, 1) == "-" and (string.find(text, "vote") or string.find(text, "kick")) then
		GameRules:SendCustomMessage("Type -votekill to start a vote to kill all for reset/stuck/afk.", 0, 1)
	end
end