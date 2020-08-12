Items = {}
local InventoriesIndex = {}
local Inventories = {} 
local SharedInventories = {}
ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Citizen.CreateThread(function()
	exports.ghmattimysql:execute('SELECT * FROM items', {}, function(items)
		for i=1, #items do
			Items[items[i].name] = items[i].label
		end
	end)

	exports.ghmattimysql:execute('SELECT * FROM addon_inventory', {}, function(result)
		for i=1, #result do
			local name   = result[i].name
			local label  = result[i].label
			local shared = result[i].shared

			exports.ghmattimysql:execute('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name', {['@inventory_name'] = name}, function(result2)
				if shared == 0 then

					table.insert(InventoriesIndex, name)
		
					Inventories[name] = {}
					local items       = {}
		
					for j=1, #result2 do
						local itemName  = result2[j].name
						local itemCount = result2[j].count
						local itemOwner = result2[j].owner
		
						if items[itemOwner] == nil then
							items[itemOwner] = {}
						end
		
						table.insert(items[itemOwner], {
							name  = itemName,
							count = itemCount,
							label = Items[itemName]
						})
					end
		
					for k,v in pairs(items) do
						local addonInventory = CreateAddonInventory(name, k, v)
						table.insert(Inventories[name], addonInventory)
					end
		
				else
					local items = {}
		
					for j=1, #result2 do
						table.insert(items, {
							name  = result2[j].name,
							count = result2[j].count,
							label = Items[result2[j].name]
						})
					end
		
					local addonInventory    = CreateAddonInventory(name, nil, items)
					SharedInventories[name] = addonInventory
				end
			end)
		end
	end)
end)

function GetInventory(name, owner)
	for i=1, #Inventories[name], 1 do
		if Inventories[name][i].owner == owner then
			return Inventories[name][i]
		end
	end
end

function GetSharedInventory(name)
	return SharedInventories[name]
end

AddEventHandler('esx_addoninventory:getInventory', function(name, owner, cb)
	cb(GetInventory(name, owner))
end)

AddEventHandler('esx_addoninventory:getSharedInventory', function(name, cb)
	cb(GetSharedInventory(name))
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local addonInventories = {}

	for i=1, #InventoriesIndex, 1 do
		local name      = InventoriesIndex[i]
		local inventory = GetInventory(name, xPlayer.identifier)

		if inventory == nil then
			inventory = CreateAddonInventory(name, xPlayer.identifier, {})
			table.insert(Inventories[name], inventory)
		end

		table.insert(addonInventories, inventory)
	end

	xPlayer.set('addonInventories', addonInventories)
end)
