local QBCore = nil
local ESX = nil
local PlayerData = {}
local isLoggedIn = false
local Framework = nil

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    if Config.Framework == 'qbcore' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qbcore'
        print('[HUD] QBCore framework detected')
    elseif Config.Framework == 'qbox' or (Config.Framework == 'auto' and GetResourceState('qbx_core') == 'started') then
        QBCore = exports.qbx_core:GetCoreObject()
        Framework = 'qbox'
        print('[HUD] QBox framework detected')
    elseif Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
        print('[HUD] ESX framework detected')
    else
        print('[HUD] No framework detected, using standalone mode')
        Framework = 'standalone'
    end
    
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    Wait(2000)
    
    if Framework == 'qbcore' or Framework == 'qbox' then
        PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and next(PlayerData) ~= nil then
            isLoggedIn = true
            SendNUIMessage({status = 'visible', data = true})
            print('[HUD] Player logged in (QBCore/QBox)')
        end
    elseif Framework == 'esx' then
        PlayerData = ESX.GetPlayerData()
        if PlayerData and PlayerData.job then
            isLoggedIn = true
            SendNUIMessage({status = 'visible', data = true})
            print('[HUD] Player logged in (ESX)')
        else
            Wait(2000)
            PlayerData = ESX.GetPlayerData()
            if PlayerData and PlayerData.job then
                isLoggedIn = true
                SendNUIMessage({status = 'visible', data = true})
                print('[HUD] Player logged in (ESX - delayed)')
            end
        end
    else
        isLoggedIn = true
        SendNUIMessage({status = 'visible', data = true})
        print('[HUD] Player logged in (Standalone)')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if Framework == 'qbcore' or Framework == 'qbox' then
        Wait(1000)
        PlayerData = QBCore.Functions.GetPlayerData()
        isLoggedIn = true
        SendNUIMessage({status = 'visible', data = true})
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if Framework == 'qbcore' or Framework == 'qbox' then
        PlayerData = {}
        isLoggedIn = false
        SendNUIMessage({status = 'visible', data = false})
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if Framework == 'qbcore' or Framework == 'qbox' then
        PlayerData = val
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if Framework == 'esx' then
        Wait(1000)
        PlayerData = xPlayer
        isLoggedIn = true
        SendNUIMessage({status = 'visible', data = true})
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    if Framework == 'esx' then
        PlayerData = {}
        isLoggedIn = false
        SendNUIMessage({status = 'visible', data = false})
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if Framework == 'esx' then
        PlayerData.job = job
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, reason)
    if Framework == 'qbcore' or Framework == 'qbox' then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if Framework == 'qbcore' or Framework == 'qbox' then
        PlayerData = val
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        
        if isLoggedIn then
            local player = PlayerPedId()
            local health = GetEntityHealth(player) - 100
            local armour = GetPedArmour(player)
            
            if health < 0 then health = 0 end
            
            local hunger = 100
            local thirst = 100
            
            if Framework == 'qbcore' or Framework == 'qbox' then
                PlayerData = QBCore.Functions.GetPlayerData()
                
                if PlayerData.metadata then
                    hunger = PlayerData.metadata["hunger"] or 100
                    thirst = PlayerData.metadata["thirst"] or 100
                end
            elseif Framework == 'esx' then
                PlayerData = ESX.GetPlayerData()
                
                TriggerEvent('esx_status:getStatus', 'hunger', function(status)
                    if status then hunger = status.getPercent() end
                end)
                TriggerEvent('esx_status:getStatus', 'thirst', function(status)
                    if status then thirst = status.getPercent() end
                end)
            end
            
            local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
            local isRunning = IsPedRunning(player) or IsPedSprinting(player)
            local showStamina = isRunning and stamina > 5
            
            SendNUIMessage({
                status = 'info',
                data = {
                    health = health,
                    armour = armour,
                    food = hunger,
                    water = thirst,
                    stamina = stamina,
                    showStamina = showStamina
                }
            })
            
            local playerId = GetPlayerServerId(PlayerId())
            local job = "Unemployed"
            local cash = 0
            local bank = 0
            
            if Framework == 'qbcore' or Framework == 'qbox' then
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
            elseif Framework == 'esx' then
                if PlayerData.job then
                    job = PlayerData.job.label or "Unemployed"
                    if PlayerData.job.grade_label then
                        job = job .. " - " .. PlayerData.job.grade_label
                    end
                end
                
                if PlayerData.accounts then
                    for _, account in pairs(PlayerData.accounts) do
                        if account.name == 'money' then
                            cash = account.money
                        elseif account.name == 'bank' then
                            bank = account.money
                        end
                    end
                end
            end
            
            SendNUIMessage({
                status = 'playerinfo',
                data = {
                    id = playerId,
                    job = job,
                    cash = cash,
                    bank = bank,
                    hideCashWhenZero = Config.HideCashWhenZero,
                    hideBankWhenZero = Config.HideBankWhenZero
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
            
            local shouldShowMinimap = Config.AlwaysShowMinimap or inVehicle
            SendNUIMessage({
                status = 'minimap',
                data = {
                    visible = shouldShowMinimap
                }
            })
            
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
        
        if Config.AlwaysShowMinimap then
            DisplayRadar(true)
        else
            local player = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(player, false)
            DisplayRadar(inVehicle)
        end
    end
end)

local seatbeltOn = false
local inVehicleWithBelt = false
local lastSoundTime = 0
local seatbeltSoundId = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        
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
                        if currentTime - lastSoundTime > 3000 then
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

if Config.ShowClock then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            
            if isLoggedIn then
                SendNUIMessage({
                    status = 'requestTime',
                    data = {
                        timezone = Config.TimeZone,
                        format = Config.ClockFormat,
                        showSeconds = Config.ShowSeconds
                    }
                })
            end
        end
    end)
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
