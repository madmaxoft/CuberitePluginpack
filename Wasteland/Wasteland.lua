local PLUGIN = nil

-- Item Definitions
dofile(cPluginManager:GetPluginsPath() .. "/Wasteland/Items.lua")

-- Crafting Related
dofile(cPluginManager:GetPluginsPath() .. "/Wasteland/CraftingRecipe.lua")
dofile(cPluginManager:GetPluginsPath() .. "/Wasteland/Recipies.lua")

-- Hook Files
dofile(cPluginManager:GetPluginsPath() .. "/Wasteland/BreakBlockHooks.lua")
dofile(cPluginManager:GetPluginsPath() .. "/Wasteland/RightClickHooks.lua")

local RegisteredWorlds = {}

function Initialize(Plugin)
	-- Load the Info.lua file
	dofile(cPluginManager:GetPluginsPath() .. "/Wasteland/Info.lua")

	PLUGIN = Plugin

	PLUGIN:SetName(g_PluginInfo.Name)
	PLUGIN:SetVersion(g_PluginInfo.Version)

	-- Generation Hooks
	cPluginManager.AddHook(cPluginManager.HOOK_CHUNK_GENERATING, OnChunkGenerating)
	cPluginManager.AddHook(cPluginManager.HOOK_CHUNK_GENERATED, OnChunkGenerated)

	-- Crafting Hooks
	cPluginManager.AddHook(cPluginManager.HOOK_PRE_CRAFTING, OnPreCrafting)

	-- Misc Hooks
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_BROKEN_BLOCK, OnBlockBroken)
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_RIGHT_CLICK, OnPlayerRightClick)
	cPluginManager.AddHook(cPluginManager.HOOK_PLUGINS_LOADED, OnPluginsLoaded)

	LOG("Initialized " .. PLUGIN:GetName() .. " v." .. PLUGIN:GetVersion())

	return true
end

function OnDisable()
	LOG("Disabled " .. PLUGIN:GetName() .. "!")
end

function OnBlockTick(World, BlockX, BlockY, BlockZ, BlockType, BlockMeta, SkyLight, BlockLight)
	LOG("Ticked block of type: " .. BlockType)
end

function OnPluginsLoaded()
	local PluginManager = cPluginManager.Get()
	if PluginManager:IsPluginLoaded('Ticker') then
		local E_BLOCK_ANY, E_META_ANY = PluginManager:CallPlugin('Ticker', 'GetAnyMarkers')
		PluginManager:CallPlugin('Ticker', 'RegisterCallback', 'world', E_BLOCK_ANY, E_BLOCK_ANY, PLUGIN:GetName(), 'OnBlockTick')
	else
		LOG("Some features will not be available without the Ticker plugin installed.")
	end
end


-- Generation Callbacks
function OnChunkGenerating(World, ChunkX, ChunkZ, ChunkDesc)
	--if (RegisteredWorlds[World.GetName()] ~= nil) then
		ChunkDesc:SetUseDefaultBiomes(false)
		ChunkDesc:SetUseDefaultFinish(false)
		-- Change the biome to desert
		for x=0,15 do
			for z=0,15 do
				ChunkDesc:SetBiome(x,z,biDesert)
			end
		end
		return true
	--end
	--return false
end

function OnChunkGenerated(World, ChunkX, ChunkZ, ChunkDesc)
	--if (RegisteredWorlds[World.GetName()] ~= nil) then
		-- Replace all water with air
		ChunkDesc:ReplaceRelCuboid(0,15, 0,255, 0,15, E_BLOCK_STATIONARY_WATER,0, E_BLOCK_AIR,0)
		ChunkDesc:ReplaceRelCuboid(0,15, 0,255, 0,15, E_BLOCK_WATER,0, E_BLOCK_AIR,0)

		-- Replace clay with hardend clay
		ChunkDesc:ReplaceRelCuboid(0,15, 0,255, 0,15, E_BLOCK_CLAY,0, E_BLOCK_HARDENED_CLAY,0)
		ChunkDesc:ReplaceRelCuboid(0,15, 0,255, 0,15, E_BLOCK_DIRT,0, E_BLOCK_DIRT, E_META_DIRT_COARSE)

		-- Cover the chunk with 4 deep in sand
		for x = 0,15 do
			for z = 0,15 do
				local y = ChunkDesc:GetHeight(x,z)
				ChunkDesc:SetBlockType(x, y + 1, z, E_BLOCK_SAND)
				ChunkDesc:SetBlockType(x, y + 2, z, E_BLOCK_SAND)
				ChunkDesc:SetBlockType(x, y + 3, z, E_BLOCK_SAND)
				ChunkDesc:SetBlockType(x, y + 4, z, E_BLOCK_SAND)
				if math.random() < 0.0003 then
					ChunkDesc:SetBlockType(x, y + 5, z, E_BLOCK_DEAD_BUSH)
				end
			end
		end

		return true
	--end
	--return false
end

-- Crafting Callbacks
function OnPreCrafting(Player, Grid, Recipe)
	local recipe_found = false
	local possible_recipie = {};

	local width = Grid:GetWidth()
	local height = Grid:GetHeight()

	for x = 1,3 do
		for y = 1,3 do
			if (x <= width and y <= height) then
				local item = Grid:GetItem(x - 1,y - 1)
				if (item ~= nil and item.m_ItemCount ~= 0) then
					table.insert(possible_recipie, item)
				else
					table.insert(possible_recipie, nil)
				end
			else
				table.insert(possible_recipie, nil)
			end
		end
	end

	for i,recipe in ipairs(wasteland_Recipies) do 
		if recipe:Compare(Grid) then
			recipe_found = true
			Recipe:SetResult(recipe:GetResult())

			for x = 0, recipe:GetWidth() - 1 do
				for y = 0, recipe:GetHeight() - 1 do
					Recipe:SetIngredient(x,y, recipe:GetItem(x,y))
				end
			end
			break
		end
	end


	return recipe_found
end





-- Block Breaking Callback
function OnBlockBroken(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	local handler = BrokenBlockHooks[BlockType]
	if handler ~= nil then
		return handler(Player, BlockX, BlockY, BlockZ, BlockFace, BlockMeta)
	end
end

-- Player Right Click Handler
function OnPlayerRightClick(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ)
	local valid, BlockType, BlockMeta = Player:GetWorld():GetBlockInfo(BlockX, BlockY, BlockZ)
	local handler = PlayerRightClick[BlockType]

	if handler ~= nil then
		return handler(Player, BlockX, BlockY, BlockZ, BlockFace, BlockMeta, CursorX, CursorY, CursorZ)
	end
end




