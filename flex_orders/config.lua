Config = {}

Config.Debug = false
Config.Lang = 'nl'
Config.CoreName = {
    qb = 'qb-core',
    esx = 'es_extended',
    ox = 'ox_core',
    ox_inv = 'ox_inventory',
    qbx = 'qbx_core',
    qb_radial = 'qb-radialmenu',
}
Config.ImagePath = "nui://ox_inventory/web/images/%s.png"


Config.Notify = {
    client = function(msg, type, time)
        lib.notify({
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
    server = function(src, msg, type, time)
        lib.notify(src, {
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
}

Config.UseSkill = false
Config.Skill = function()
    return exports.flex_skills:getSkillLevel(Config.SkillName)
end

Config.Mail = {
    client = function(sender, subject, message)
        TriggerServerEvent('flex_orders:server:SendYSeriesMail', sender, subject, message)
        -- TriggerServerEvent('phone:sendNewMail', {
        --     sender = sender,
        --     subject = subject,
        --     message = message
        -- })
    end,
    server = function(sender, subject, message, id)
        TriggerEvent('flex_orders:server:SendYSeriesMail', sender, subject, message, id)
        -- exports['qs-smartphone-pro']:sendNewMail(id, {
        --     sender = sender,
        --     subject = subject,
        --     message = message
        -- })
    end,
}

Config.OrderPed = {
    model = false,
    coords = vector4(216.45817565918, -915.64099121094, 31.78374671936, 198.02462768555),
}
Config.DeliverTime = math.random(1,2) -- Time in minutes to get a location
Config.GlobalBlipChance = 15 -- % out of 100 so everyone except police / medic get a blip
Config.BlipsTime = math.random(5,7) -- Time in minutes the blip stays on the gps
Config.RadiusblipTime = math.random(13,18) -- Time in minutes the radious blip stay on the map
Config.DeliverLocs = {
    [1] = {
        inUse = false,
        peds = {
            [1] = {
                model = 's_m_y_dockwork_01',
                coords = vector4(187.44, -2202.36, 5.96, 45.92),
            },
            [2] = {
                model = 's_m_m_dockwork_01',
                coords = vector4(194.92, -2200.96, 6.96, 63.24),
            },
            [3] = {
                model = 's_m_y_construct_01',
                coords = vector4(191.28, -2202.04, 5.96, 36.96),
            },
        },
        crate = vector4(189.6, -2199.2, 5.96, 80.92),
    },
    [2] = {
        inUse = false,
        peds = {
            [1] = {
                model = 's_m_y_dockwork_01',
                coords = vector4(193.16, -2504.32, 7.24, 230.76),
            },
            [2] = {
                model = 's_m_m_dockwork_01',
                coords = vector4(207.04, -2490.92, 6.0, 137.6),
            },
            [3] = {
                model = 's_m_y_construct_01',
                coords = vector4(197.92, -2491.24, 6.0, 231.76),
            },
            [4] = {
                model = 's_m_y_construct_01',
                coords = vector4(197.08, -2496.76, 10.76, 237.24),
            },
        },
        crate = vector4(202.68, -2499.64, 6.0, 151.56),
    },
    [3] = {
        inUse = false,
        peds = {
            [1] = {
                model = 's_m_y_dockwork_01',
                coords = vector4(496.04, -2801.32, 8.92, 77.76),
            },
            [2] = {
                model = 's_m_m_dockwork_01',
                coords = vector4(475.8, -2790.24, 6.04, 205.76),
            },
            [3] = {
                model = 's_m_y_construct_01',
                coords = vector4(482.92, -2787.68, 6.04, 190.44),
            },
            [4] = {
                model = 's_m_y_construct_01',
                coords = vector4(490.12, -2791.8, 6.04, 113.0),
            },
        },
        crate = vector4(484.48, -2793.6, 6.04, 146.96),
    },
}

Config.MoneType = 'black_money' -- 'blackmoney', 'cash', 'bank'
Config.SkillName = 'crime'
Config.OrderItems = {
    [1] = {
        name = 'lockpick',
        label = 'Lockpick',
        price = 100,
        rep = 0,
        max = 10, -- Max amount you can order
    },
}

Config.PedWeapons = {
    "weapon_snspistol",
    "weapon_heavypistol",
    "weapon_microsmg",
    "weapon_smg_mk2",
    "weapon_smg",
    "weapon_machinepistol",
    "weapon_assaultrifle",
    "weapon_advancedrifle",
    "weapon_carbinerifle_mk2",
}