local Gallows = {
    {['coords'] = vector3(-314.2954, 727.2396, 120.6202), ['hang'] = vector3(-314.4, 728.7, 121.15)}, -- Valentine
    {['coords'] = vector3(2690.89, -1113.945, 52.83637), ['hang'] = vector3(0.0, 0.0, 0.0)} -- St. Denis
}
local cooldowntimer = 0
local Hanggroup = GetRandomIntInRange(0, 0xffffff)
local active = false
local Hangprompt
function Hangprompt()
    Citizen.CreateThread(
        function()
            local str = 'Hang a Person'
            local wait = 0
            Hangprompt = Citizen.InvokeNative(0x04F97DE45A519419)
            PromptSetControlAction(Hangprompt, 0xC7B5340A)
            str = CreateVarString(10, 'LITERAL_STRING', str)
            PromptSetText(Hangprompt, str)
            PromptSetEnabled(Hangprompt, true)
            PromptSetVisible(Hangprompt, true)
            PromptSetHoldMode(Hangprompt, true)
            PromptSetGroup(Hangprompt, Hanggroup)
            PromptRegisterEnd(Hangprompt)
        end
    )
end

Citizen.CreateThread(
    function()
        Hangprompt()
        while true do
            Wait(0)
            local pedCoords = GetEntityCoords(PlayerPedId())
            for k, v in pairs(Gallows) do
                local dist = Vdist(pedCoords.x, pedCoords.y, pedCoords.z, v.coords.x, v.coords.y, v.coords.z, 0.0)
                if dist < 2.0 and not active and cooldowntimer == 0 then
                    local HangGroupName = CreateVarString(10, 'LITERAL_STRING', 'Gallows')
                    PromptSetActiveGroupThisFrame(Hanggroup, HangGroupName)
                    if PromptHasHoldModeCompleted(Hangprompt) then
                        cooldowntimer = 100
                        active = true
                        local closestPlayer = GetClosestPlayer()
                        if closestPlayer ~= nil and closestPlayer ~= -1 then
                            TriggerServerEvent('rsg-hanging:policeCheck', GetPlayerServerId(closestPlayer), k)
                            cooldown()
                        else
                            PlaySoundFrontend('Witness', 'HUD_Wanted_Sounds', true, 1)
                            lib.notify(
                                {
                                    title = 'There is no players nearby!',
                                    type = 'error',
                                    duration = 5000
                                }
                            )
                            cooldown()
                        end
                    end
                else
                    active = false
                end
            end
        end
    end
)

RegisterNetEvent('rsg-hanging:doHang')
AddEventHandler(
    'rsg-hanging:doHang',
    function(closestPlayer, id)
        local player = GetPlayerFromServerId(closestPlayer)
        local targetPed = GetPlayerPed(player)
        local ped = PlayerPedId()
        Citizen.CreateThread(
            function()
                local cigar =
                    CreateObject(
                    GetHashKey('p_cigar01x'),
                    Gallows[id]['hang'].x,
                    Gallows[id]['hang'].y,
                    Gallows[id]['hang'].z,
                    true,
                    true,
                    false,
                    false,
                    false
                )
                AttachEntityToEntity(
                    targetPed,
                    cigar,
                    0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    0.0,
                    120.0,
                    false,
                    false,
                    false,
                    true,
                    0.0,
                    true,
                    false,
                    false
                )
                Wait(1000)
                DeleteObject(cigar)
                DetachEntity(targetPed, true, true)
                ResetPedRagdollTimer(targetPed)
                SetEntityHealth(PlayerPedId(), 0)
            end
        )
    end
)

function cooldown()
    Citizen.CreateThread(
        function()
            while cooldowntimer > 0 do
                Wait(0)
                cooldowntimer = cooldowntimer - 1
            end
        end
    )
end

function GetClosestPlayer()
    local players = GetPlayers()
    local closestDistance = 3
    local closestPlayer = -1
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply)

    for index, value in ipairs(players) do
        local target = GetPlayerPed(value)
        if (target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = Vdist(targetCoords, plyCoords)
            --print(distance)
            if (closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end
