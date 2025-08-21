
function NativeIsPedLassoed(ped)
    return Citizen.InvokeNative(0x9682F850056C9ADE, ped)
end

---@param ped number
---@return boolean
function canOpenTarget(ped)
    return IsPedFatallyInjured(ped)
        or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
        or IsPedCuffed(ped)
        or NativeIsPedLassoed(ped)
        or N_0xb655db7582aec805(ped) == 0
        or IsPedDeadOrDying( ped )
        or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
        or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
        or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_enter', 3)
        or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
        or IsEntityPlayingAnim(ped, 'script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs',
            'handsup_register_owner', 3)
end

--- example
api.addModel(models.specialBrush,
    {
        {
            name = 'Plant-Harvest',
            label = "Coletar Planta",
            event = "Plant-Collect:Special",
            distance = 2,
        }
    })

--- example
api.addGlobalPlayer({
    {
        name = 'give_money',
        label = "Dar dinheiro",
        event = "interact:player:giveMoney",
        distance = 2,
    },
    {
        name = 'SearchPlayer_05',
        label = "Revistar",
        event = "police:client:SearchPlayer",
        distance = 2,
        canInteract = function(entity, distance, coords, name, bone)
            return canOpenTarget(entity)
        end
    },
})

--- example
api.addSphereZone(
    {
        coords = vector3(2508.56, -936.98, 41.99),
        name = "moinho",
        radius = 4.0,
        drawSprite = true,
        options = {
            {
                name = 'moinho',
                label = "Moinho",
                event = "FRP:CRAFTING:client_TryToOpenCrafting",
                distance = 4,
            },
        }
    }
)
