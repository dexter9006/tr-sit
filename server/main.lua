local QBCore = exports['qb-core']:GetCoreObject()
local seatsTaken = {}

RegisterNetEvent('tr-sittakePlace', function(objectCoords)
	seatsTaken[objectCoords] = true
end)

RegisterNetEvent('tr-sitleavePlace', function(objectCoords)
	if seatsTaken[objectCoords] then
		seatsTaken[objectCoords] = nil
	end
end)

QBCore.Functions.CreateCallback('tr-sitgetPlace', function(source, cb, objectCoords)
	cb(seatsTaken[objectCoords])
end)
