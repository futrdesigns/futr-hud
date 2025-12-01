local QBCore = nil
local PlayerData = {}
local isLoggedIn = false

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core:GetCoreObject()
    end
    
    if QBCore then
        Citizen.Wait(500)
        PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and next(PlayerData) ~= nil then
            isLoggedIn = true
            SendNUIMessage({status = 'visible', data = true})
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    SendNUIMessage({status = 'visible', data = true})
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
    SendNUIMessage({status = 'visible', data = false})
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if isLoggedIn and QBCore then
            local player = PlayerPedId()
            local health = GetEntityHealth(player) - 100
            local armour = GetPedArmour(player)
            
            if health < 0 then health = 0 end
            
            local hunger = 100
            local thirst = 100
            
            if PlayerData.metadata then
                hunger = PlayerData.metadata["hunger"] or 100
                thirst = PlayerData.metadata["thirst"] or 100
            end
            
            SendNUIMessage({
                status = 'info',
                data = {
                    health = health,
                    armour = armour,
                    food = hunger,
                    water = thirst
                }
            })
            
            local playerId = GetPlayerServerId(PlayerId())
            local job = "Unemployed"
            local cash = 0
            local bank = 0
            
            if PlayerData.job then
                job = PlayerData.job.label or "Unemployed"
                if PlayerData.job.grade and PlayerData.job.grade.name then
                    job = job .. " - " .. PlayerData.job.grade.name
                end
            end
            
            if PlayerData.money then
                cash = PlayerData.money["cash"] or 0
                bank = PlayerData.money["bank"] or 0
            end
            
            SendNUIMessage({
                status = 'playerinfo',
                data = {
                    id = playerId,
                    job = job,
                    cash = cash,
                    bank = bank
                }
            })
        end
    end
end)

local directions = {
    [0] = 'N', [45] = 'NE', [90] = 'E', [135] = 'SE',
    [180] = 'S', [225] = 'SW', [270] = 'W', [315] = 'NW', [360] = 'N',
}

function GetDirection()
    local player = PlayerPedId()
    local heading = GetEntityHeading(player)
    
    for angle, dir in pairs(directions) do
        if math.abs(heading - angle) < 22.5 then
            return dir
        end
    end
    
    if heading >= 337.5 or heading < 22.5 then
        return 'N'
    elseif heading >= 22.5 and heading < 67.5 then
        return 'NE'
    elseif heading >= 67.5 and heading < 112.5 then
        return 'E'
    elseif heading >= 112.5 and heading < 157.5 then
        return 'SE'
    elseif heading >= 157.5 and heading < 202.5 then
        return 'S'
    elseif heading >= 202.5 and heading < 247.5 then
        return 'SW'
    elseif heading >= 247.5 and heading < 292.5 then
        return 'W'
    elseif heading >= 292.5 and heading < 337.5 then
        return 'NW'
    end
    
    return 'N'
end

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Wait(2000)
    
    SendNUIMessage({
        status = 'location',
        data = {
            street = "Loading...",
            area = "Loading...",
            direction = "N"
        }
    })
    
    while true do
        Wait(250) 
        
        local player = PlayerPedId()
        
        if DoesEntityExist(player) and not IsEntityDead(player) then
            local coords = GetEntityCoords(player)
            
            local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local streetName = GetStreetNameFromHashKey(streetHash)
            
            local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
            local zoneName = GetLabelText(zoneHash)
            
            if zoneName == zoneHash or zoneName == "UNKNOWN" or zoneName == "" then
                zoneName = zoneHash
                if zoneName == "UNKNOWN" or zoneName == "" then
                    zoneName = "San Andreas"
                end
            end
            
            local direction = GetDirection()
            
            local displayStreet = "Unknown Road"
            if streetName and streetName ~= "" and streetName ~= "NULL" then
                displayStreet = streetName
            end
            
            SendNUIMessage({
                status = 'location',
                data = {
                    street = displayStreet,
                    area = zoneName,
                    direction = direction
                }
            })
        end
    end
end)

Citizen.CreateThread(function()
    local wasInVehicle = false
    local wasArmed = false
    
    while true do
        Citizen.Wait(200)
        
        if isLoggedIn then
            local pause = IsPauseMenuActive()
            if pause then
                SendNUIMessage({status = 'visible', data = false})
            else
                SendNUIMessage({status = 'visible', data = true})
            end
            
            local player = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(player, false)
            
            if inVehicle then
                local vehicle = GetVehiclePedIsIn(player, false)
                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == player then
                    local speed = GetEntitySpeed(vehicle)
                    if Config.UseMPH then
                        speed = speed * 2.236936
                    else
                        speed = speed * 3.6
                    end
                    
                    local fuel = GetVehicleFuelLevel(vehicle)
                    local engine = GetVehicleEngineHealth(vehicle) / 10
                    
                    SendNUIMessage({
                        status = 'speedometer',
                        data = {
                            visible = true,
                            speed = math.floor(speed),
                            engine = math.floor(engine),
                            fuel = math.floor(fuel),
                            mph = Config.UseMPH
                        }
                    })
                    
                    wasInVehicle = true
                end
            else
                if wasInVehicle then
                    SendNUIMessage({
                        status = 'speedometer',
                        data = {visible = false}
                    })
                    wasInVehicle = false
                end
            end
            
            local isArmed = IsPedArmed(player, 4)
            if isArmed then
                local weaponHash = GetSelectedPedWeapon(player)
                if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
                    local ammoInClip = GetAmmoInClip(player, weaponHash)
                    local maxAmmo = GetMaxAmmoInClip(player, weaponHash, true)
                    local totalAmmo = GetAmmoInPedWeapon(player, weaponHash)
                    
                    SendNUIMessage({
                        status = 'weapon',
                        data = {
                            visible = true,
                            ammoInClip = ammoInClip,
                            maxAmmo = maxAmmo,
                            totalAmmo = (totalAmmo - ammoInClip)
                        }
                    })
                    
                    wasArmed = true
                end
            else
                if wasArmed then
                    SendNUIMessage({
                        status = 'weapon',
                        data = {visible = false}
                    })
                    wasArmed = false
                end
            end
        end
    end
end)

if GetResourceState('pma-voice') == 'started' then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(100)
            
            if isLoggedIn then
                local isTalking = NetworkIsPlayerTalking(PlayerId())
                local voiceMode = LocalPlayer.state.proximity and LocalPlayer.state.proximity.index or 2
                
                SendNUIMessage({
                    status = 'voice',
                    data = {
                        talking = isTalking,
                        mode = voiceMode
                    }
                })
            end
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        HideHudComponentThisFrame(3)
        HideHudComponentThisFrame(4) 
        HideHudComponentThisFrame(6)  
        HideHudComponentThisFrame(7) 
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9) 
        HideHudComponentThisFrame(13)
        
        DisplayAmmoThisFrame(false)
        DisplaySniperScopeThisFrame(false)
        
        DisplayRadar(true)
    end
end)

local seatbeltOn = false
local inVehicleWithBelt = false
local lastSoundTime = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if isLoggedIn then
            local player = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(player, false)
            
            if inVehicle then
                local vehicle = GetVehiclePedIsIn(player, false)
                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == player then
                    inVehicleWithBelt = true
                    
                    local speed = GetEntitySpeed(vehicle)
                    local shouldWarn = not seatbeltOn and speed > 5.0
                    
                    if shouldWarn then
                        local currentTime = GetGameTimer()
                        if currentTime - lastSoundTime > 5000 then
                            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                            lastSoundTime = currentTime
                        end
                    end
                    
                    SendNUIMessage({
                        status = 'seatbelt',
                        data = {
                            show = true,
                            on = seatbeltOn,
                            warn = shouldWarn
                        }
                    })
                else
                    if inVehicleWithBelt then
                        SendNUIMessage({
                            status = 'seatbelt',
                            data = { show = false }
                        })
                        inVehicleWithBelt = false
                        seatbeltOn = false
                    end
                end
            else
                if inVehicleWithBelt then
                    SendNUIMessage({
                        status = 'seatbelt',
                        data = { show = false }
                    })
                    inVehicleWithBelt = false
                    seatbeltOn = false
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isLoggedIn and inVehicleWithBelt then
            if IsControlJustPressed(0, 29) then 
                seatbeltOn = not seatbeltOn
                PlaySoundFrontend(-1, "TOGGLE_ON", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                
                SendNUIMessage({
                    status = 'seatbelt',
                    data = {
                        show = true,
                        on = seatbeltOn,
                        warn = false
                    }
                })
            end
        end
    end
end)

Citizen.CreateThread(function()
    local function setupMinimap()
        RequestStreamedTextureDict("squaremap", false)
        while not HasStreamedTextureDictLoaded("squaremap") do
            Wait(150)
        end
        
        SetMinimapClipType(0)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
        
        SetMinimapComponentPosition("minimap", "L", "B", 0.015, -0.03, 0.155, 0.188)
        SetMinimapComponentPosition("minimap_mask", "L", "B", 0.015, 0.015, 0.155, 0.225)
        SetMinimapComponentPosition("minimap_blur", "L", "B", 0.012, 0.022, 0.256, 0.337)
        
        SetRadarBigmapEnabled(false, false)
        SetRadarZoom(1000)
    end
    
    setupMinimap()
end)

function GetAmmoInClip(ped, weaponHash)
    local ammoClip = Citizen.InvokeNative(0x2E1202248937775C, ped, weaponHash, Citizen.PointerValueInt())
    return ammoClip
end

RegisterCommand('hudloc', function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local zoneHash = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneName = GetLabelText(zoneHash)
    
    print("=== HUD Location Debug ===")
    print("Player Exists: " .. tostring(DoesEntityExist(player)))
    print("Player Dead: " .. tostring(IsEntityDead(player)))
    print("Coords: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
    print("Street Hash: " .. tostring(streetHash))
    print("Street Name: " .. tostring(streetName))
    print("Zone Hash: " .. tostring(zoneHash))
    print("Zone Name: " .. tostring(zoneName))
    print("Direction: " .. GetDirection())
    print("Network Active: " .. tostring(NetworkIsPlayerActive(PlayerId())))
    print("=========================")
    
    SendNUIMessage({
        status = 'location',
        data = {
            street = streetName or "Test Street",
            area = zoneName or "Test Area",
            direction = GetDirection()
        }
    })
end, false)
