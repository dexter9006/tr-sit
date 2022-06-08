local QBCore = exports['qb-core']:GetCoreObject()
local debugProps, sitting, lastPos, currentSitCoords, currentScenario, occupied = {}
local disableControls = false
local currentObj = nil

exports('sitting', function()
    return sitting
end)

CreateThread(function()
	while true do
		Wait(0)
		local playerPed = PlayerPedId()

		if sitting then
			if Config.DrawText == "QB" then
				exports['qb-core']:DrawText(Config.Text["StandUp"], Config.DrawTextLocation)
			elseif Config.DrawText == "CD" then
				TriggerEvent('cd_drawtextui:ShowUI', 'show', Config.Text["StandUp"])
			end
		end

		if sitting and not IsPedUsingScenario(playerPed, currentScenario) then
			if Config.DrawText == "QB" then
				exports['qb-core']:HideText()
			elseif Config.DrawText == "CD" then
				TriggerEvent('cd_drawtextui:HideUI')
			end
			wakeup()
		end

		if IsControlPressed(0, Config.GetUpKey) and IsInputDisabled(0) and IsPedOnFoot(playerPed) then
			if sitting then
				if Config.DrawText == "QB" then
					exports['qb-core']:KeyPressed()
				elseif Config.DrawText == "CD" then
					TriggerEvent('cd_drawtextui:HideUI')
				end
				Wait(7)
				wakeup()
			end
		end
	end
end)

CreateThread(function()
	local Sitables = {}

	for _, v in pairs(Config.Interactables) do
		local model = GetHashKey(v)
		table.insert(Sitables, model)
	end
	Wait(100)
	exports['qb-target']:AddTargetModel(Sitables, {
        options = {
            {
                event = "qb-Sit:Sit",
                icon = "fas fa-chair",
                label = Config.Text["TargetLabel"],
				entity = entity
            },
        },
        job = {"all"},
        distance = Config.MaxDistance
    })
end)

RegisterNetEvent("qb-Sit:Sit", function(data)
	local playerPed = PlayerPedId()

	if sitting and not IsPedUsingScenario(playerPed, currentScenario) then
		wakeup()
	end

	if disableControls then
		DisableControlAction(1, 37, true)
	end

	local object, distance = data.entity, #(GetEntityCoords(playerPed) - GetEntityCoords(data.entity))

	if distance and distance < 1.4 then
		local hash = GetEntityModel(object)

		for k,v in pairs(Config.Sitable) do
			if GetHashKey(k) == hash then
				sit(object, k, v)
				break
			end
		end
	end
end)


function wakeup()
	local playerPed = PlayerPedId()
	local pos = GetEntityCoords(PlayerPedId())

	TaskStartScenarioAtPosition(playerPed, currentScenario, 0.0, 0.0, 0.0, 180.0, 2, true, false)
	while IsPedUsingScenario(PlayerPedId(), currentScenario) do
		Wait(100)
	end
	ClearPedTasks(playerPed)

	FreezeEntityPosition(playerPed, false)
	FreezeEntityPosition(currentObj, false)
	TriggerServerEvent('tr-sitleavePlace', currentSitCoords)
	currentSitCoords, currentScenario = nil, nil
	sitting = false
	disableControls = false
end

function sit(object, modelName, data)
	if not HasEntityClearLosToEntity(PlayerPedId(), object, 17) then
		return
	end
	disableControls = true
	currentObj = object
	FreezeEntityPosition(object, true)

	PlaceObjectOnGroundProperly(object)
	local pos = GetEntityCoords(object)
	local playerPos = GetEntityCoords(PlayerPedId())
	local objectCoords = pos.x .. pos.y .. pos.z

	QBCore.Functions.TriggerCallback('tr-sitgetPlace', function(occupied)
		if occupied then
			QBCore.Functions.Notify(Config.Text["Occupied"], 'error')
		else
			local playerPed = PlayerPedId()
			lastPos, currentSitCoords = GetEntityCoords(playerPed), objectCoords

			TriggerServerEvent('tr-sittakePlace', objectCoords)

			currentScenario = data.scenario
			TaskStartScenarioAtPosition(playerPed, currentScenario, pos.x, pos.y, pos.z + (playerPos.z - pos.z)/2, GetEntityHeading(object) + 180.0, 0, true, false)

			Wait(2500)
			if GetEntitySpeed(PlayerPedId()) > 0 then
				ClearPedTasks(PlayerPedId())
				TaskStartScenarioAtPosition(playerPed, currentScenario, pos.x, pos.y, pos.z + (playerPos.z - pos.z)/2, GetEntityHeading(object) + 180.0, 0, true, true)
			end

			sitting = true
		end
	end, objectCoords)
end