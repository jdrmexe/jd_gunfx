
local rpgHash = GetHashKey('WEAPON_RPG')
local lastShot = 0
local cooldown = 1000

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weapon == rpgHash and IsPedShooting(ped) then
            local now = GetGameTimer()

            if now - lastShot >= cooldown then
                lastShot = now

                SendNUIMessage({
                    action = 'playRpgSound'
                })
            end
        end
    end
end)
