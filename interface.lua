------------------------------------------------------------------------------------------
--[[REMOTE INTERFACES]]-- Command Line and access from other mods is enabled here.
--luacheck: globals autofill
local interface = {}

interface.console = require("stdlib/debug/console")

--Dump the "global" to console and logfile
function interface.print_global(name)
    if name and type(name) == "string" then
        --MOD.log(global[name], 2)
        game.write_file(MOD.fullname.."/global.lua", serpent.block(global[name], {comment=false, sparse=true, compact=true, name="global."..name, indent="    "}))
    else
        --MOD.log(global, 2)
        game.write_file(MOD.fullname.."/global.lua", serpent.block(global, {comment=false, sparse=true, compact=true, name="global", indent="    "}))
    end
end

function interface.config(key, value, silent)
    local config = Config.new(global.config)
    local level = (silent and 1) or 2
    if key then
        if key == "reset" then
            global.config = table.deepcopy(MOD.config.control)
            MOD.log("Reset config to default.", level)
            return true
        end
        --key=string.upper(key)
        if config.get(key) ~= nil then
            if value ~= nil then
                config.set(key, value)
                local val=config.get(key)
                MOD.log("New value for '" .. key .. "' is " .. "'" .. tostring(val) .."'", level)
                return val-- all is well
            else --value nil
                local val = config.get(key)
                MOD.log("Current value for '" .. key .. "' is " .. "'" .. tostring(val) .."'", level)
                return val
            end
        else --key is nill
            MOD.log("Config '" .. key .. "' does not exist", level)
            return nil
        end
    else
        if not silent then
            MOD.log("Config requires a key name", level)
            MOD.log(global.config, level)
        end
        return nil
    end
end

-------------------------------------------------------------------------------
--[[Reset functions]]
--Complete reset of the mod. Wipes everything.
function interface.reset_mod()
    MOD.on_init()
    MOD.log(MOD.name .. " Reset Complete", 2)
end

function interface.reset_all_sets()
    autofill.sets.verify.default_sets()
    interface.reset_global_sets()
    interface.reset_force_sets()
    interface.reset_player_sets()
end

function interface.reset_global_sets()
    --global.sets = autofill.sets.global.new()
    autofill.sets.global.reset_sets()
end

function interface.reset_force(force)
    if force then
        if type(force) == "table" then force = force.name end
        autofill.init_force(force, true)
    else
        autofill.init_force(nil, true)
    end
end

function interface.reset_force_sets(force)
    if force then
        autofill.sets.force.reset_sets(global.forces[force.name].sets)
    else
        for _, force_data in pairs(global.forces) do
            autofill.sets.force.reset_sets(force_data.sets)
        end
    end
end

function interface.reset_player(player)
    if player then
        autofill.init_player(player.index, true)
    else
        autofill.init_player(nil, true)
    end
end

function interface.reset_player_sets(player)
    if player then
        autofill.sets.player.reset_sets(global.players[player.index].sets)
    else
        for _, player_data in pairs(global.players) do
            autofill.sets.player.reset_sets(player_data.sets)
        end
    end
end

function interface.update_and_verify_saved_sets(safe_merge)
    autofill.sets.verify.default_sets()
    autofill.sets.verify.update_and_verify_saved_sets(safe_merge)
    game.write_file(MOD.fullname.."/global.lua", serpent.block(global, {comment=false, sparse=true, compact=true, name="global", indent="    "}))
end

-------------------------------------------------------------------------------
--[[Toggle functions]]

function interface.toggle_or_set_global_enabled(enabled)
    if enabled ~= nil then
        global.enabled = enabled
        return enabled
    else
        global.enabled = not global.enabled
        return global.enabled
    end
end

function interface.toggle_or_set_player_enabled(player, enabled)
    --player = Game.get_valid_player(player)
    if player and player.valid then
        if global.players[player.index] then
            if enabled ~= nil then
                global.players[player.index].enabled = enabled
                return enabled
            else
                global.players[player.index].enabled = not global.players[player.index].enabled
                return global.players[player.index].enabled
            end
        end
    end
end

-------------------------------------------------------------------------------
--[[Insert functions]]

function interface.insert_player_set()
end
function interface.insert_force_set()
end
function interface.insert_global_set()
end

-------------------------------------------------------------------------------
--[[creative-mode-functions]]

local function register_cm_interface(disable)
    --Register with creative-mode for easy testing
    if remote.interfaces["creative-mode"] and remote.interfaces["creative-mode"]["register_remote_function_to_modding_ui"] then
        MOD.log("Registering with Creative Mode")
        remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "print_global")
        remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset_mod")
        remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "verify_saved_sets")
        remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "console")
        if disable then interface.creative_mode_register = nil end
    end
end

function interface.creative_mode_register()
    register_cm_interface()
end
register_cm_interface(true)

return interface
