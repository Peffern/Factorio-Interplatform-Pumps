-- when processing entities during a tick, we dont want to process every tick (too expensive)
-- but we dont want to wait a period then do every process on the same tick (too laggy during that tick)
-- so we want to spread the processing out across many ticks.
-- we do this by taking the unit number `mod` shard count, and tick number `mod` shard count,
-- and processing any entities that match.
-- to make lookups faster, all stored tables are indexed first by this modded index, then by the actual index.
-- so for instance, storage.some_table[my_entity.unit_number % shard_count][my_entity.unit_number]
-- the reason for this is that it means getting all entities that need to be processed for a given tick
-- can be done by pairs(storage.some_table[tick_count % shard_count]) and not need to parse the whole table.
-- smaller numbers here mean less latency with update at the cost of performance
local shard_count = 10

-- runs on init (once) to set up storage tables

function setup()
    storage.platform_orbit_states = {}
    storage.exporter_states = {}
    storage.importer_states = {}

    -- NOTE that this is 0 indexed in order to make the modulo work out not 1 indexed like most lua tables
    for i = 1,shard_count do
        storage.platform_orbit_states[i - 1] = {}
        storage.exporter_states[i - 1] = {}
        storage.importer_states[i - 1] = {}
    end
end


-- callback for when any assembler is built
function assembler_built(event) 
    -- different events have different payloads
    local entity = event.created_entity or event.entity or event.destination

    -- make sure we have a real jet object otherwise skip
    if not (entity and entity.valid and entity.name == "jet") then return end

    -- set inactive so it doesnt try to run the dummy recipe, then set and lock recipe
    entity.active = false
    entity.set_recipe("jet")
    entity.recipe_locked = true

end

-- gui stuff

function on_gui_open(event)
    local player = game.get_player(event.player_index)

    if not (event.gui_type == defines.gui_type.entity and event.entity and event.entity.valid and player) then return end

    if event.entity.name == "space-platform-hub" then
        show_orbit_gui(player, event)
    elseif event.entity.name == "exporter" or event.entity.name == "importer" then
       show_port_id_gui(player, event)
    end
end

function show_orbit_gui(player, event)
    local gui = player.gui.relative["orbit-adjustment"]

    if gui then return end

    local unit_number = event.entity.unit_number

    local existing_state = storage.platform_orbit_states[unit_number % shard_count][unit_number] or {}

    local signal_data = existing_state.orbit_destination_signal -- default is nil so don't need to add a default here
    -- if it's not nil, this will be like {type="item", name="thruster"} or something else that can be pasted to the gui element
    
    gui = player.gui.relative.add({
        type = "frame",
        name = "orbit-adjustment",
        caption = { "TODO_orbit_gui.title" }, -- TODO gui title
        direction = "vertical",
        index = 0,
        anchor = {
            gui = defines.relative_gui_type.space_platform_hub_gui,
            position = defines.relative_gui_position.bottom
        }
    })
    local inner = gui.add({
        type = "frame",
        name = "orbit_destination_inner",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical",
    })
    local flow = inner.add({
        type = "flow",
        name = "orbit_destination_flow",
        style = "player_input_horizontal_flow"
    })
    flow.add({
        type = "label",
        name = "orbit_destination_label",
        caption = { "TODO_orbit_gui.label" },
    })
    flow.add({
        type = "choose-elem-button",
        name = "orbit_destination_signal_button", 
        elem_type = "signal",
        signal = signal_data
    })    
end

function show_port_id_gui(player, event)
    local gui = player.gui.relative["port-id"]

    if gui then return end

    local unit_number = event.entity.unit_number

    local storage_key = "exporter_states"
    if event.entity.name == "importer" then storage_key = "importer_states" end

    local existing_state = storage[storage_key][unit_number % shard_count][unit_number] or {}

    local signal_data = existing_state.port_id_signal -- default is nil so don't need to add a default here
    -- if it's not nil, this will be like {type="item", name="thruster"} or something else that can be pasted to the gui element
    
    gui = player.gui.relative.add({
        type = "frame",
        name = "port-id",
        caption = { "TODO_port_gui.title" }, -- TODO gui title
        direction = "vertical",
        index = 0,
        anchor = {
            gui = defines.relative_gui_type.entity_with_energy_source_gui,
            position = defines.relative_gui_position.right
        }
    })
    local inner = gui.add({
        type = "frame",
        name = "port_id_inner",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical",
    })
    local flow = inner.add({
        type = "flow",
        name = "port_id_flow",
        style = "player_input_horizontal_flow"
    })
    flow.add({
        type = "label",
        name = "port_id_label",
        caption = { "TODO_port_gui.label" },
    })
    flow.add({
        type = "choose-elem-button",
        name = "port_id_signal_button", 
        elem_type = "signal",
        signal = signal_data
    })
end



function on_gui_close(event)
    local player = game.get_player(event.player_index)

    if not (event.gui_type == defines.gui_type.entity and event.entity and event.entity.valid and player) then return end
    
    local gui = nil

    if event.entity.name == "space-platform-hub" then
        gui = player.gui.relative["orbit-adjustment"]
    elseif event.entity.name == "exporter" or event.entity.name == "importer" then
        gui = player.gui.relative["port-id"]
    end

    if not gui then return end

    gui.destroy()
end

function on_gui_change(event)
    local player = game.get_player(event.player_index)
    
    if not player then return end

    if event.element.name == "orbit_destination_signal_button" then
        -- player changed signal on the orbit gui so we want to store the new signal value

        local unit_number = player.opened.unit_number

        if not unit_number then return end

        if not (storage.platform_orbit_states[unit_number % shard_count][unit_number]) then
            storage.platform_orbit_states[unit_number % shard_count][unit_number] = {
                -- TODO initialize other values here, gather into a standard constructor fn, etc.
            }
        end

        -- since it's a signal button, elem_value will be the signal data and we can store it directly in the table
        storage.platform_orbit_states[unit_number % shard_count][unit_number].orbit_destination_signal = event.element.elem_value
    elseif event.element.name == "port_id_signal_button" then
        local unit_number = player.opened.unit_number
        
        if not unit_number then return end

        local storage_key = "exporter_states"

        if player.opened.name == "importer" then storage_key = "importer_states" end

        
        if not (storage[storage_key][unit_number % shard_count][unit_number]) then
            storage[storage_key][unit_number % shard_count][unit_number] = {
                -- TODO initialize other values here, gather into a standard constructor fn, etc.
            }
        end

        -- since it's a signal button, elem_value will be the signal data and we can store it directly in the table
        storage[storage_key][unit_number % shard_count][unit_number].port_id_signal = event.element.elem_value
    
    end
end

script.on_event(defines.events.on_built_entity, assembler_built, {{filter = "type", type = "assembling-machine"}})
script.on_event(defines.events.on_robot_built_entity, assembler_built, {{filter = "type", type = "assembling-machine"}})
script.on_event(defines.events.script_raised_built, assembler_built, {{filter = "type", type = "assembling-machine"}})
script.on_event(defines.events.script_raised_revive, assembler_built, {{filter = "type", type = "assembling-machine"}})
script.on_event(defines.events.on_space_platform_built_entity, assembler_built, {{filter = "type", type = "assembling-machine"}})
script.on_event(defines.events.on_entity_cloned, assembler_built, {{filter = "type", type = "assembling-machine"}})



script.on_event(defines.events.on_gui_opened, on_gui_open) 
script.on_event(defines.events.on_gui_closed, on_gui_close) 
script.on_event(defines.events.on_gui_elem_changed, on_gui_change)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_change) 

script.on_init(setup)

-- everything should be in place
--[[

    so then plan for on_tick is:

    for space platforms, see if they have a set signal.
    if yes read the corresponding signal, and get the value.
    if it isnt matching the current orbit position then try to put us in transit.
        
    i.e. make sure we dont have 2 already there or in transit. then set us in transit and set progress to 0.
        
    also handle cancels, i.e. if it does match and we arent stopped, then stop.
    TODO handle case where we turn around but someone took our spot. do we hold both? do we swap the progress bar around?

    for thrusters, if were currently in transit then try to do a tick.
    that means, drain fuel + oxidizer and and tick up the progress bar.
    include completion, if it fills then we go to stopped and not in transit any more.

    
    everything else assumes we're stopped. if we're in transit or waiting, then we dont do anything here.

    exporters, check if they have a signal. if yes read the signal. get a value, skip if nil.
    for importers, ditto mark.

    store this in a lookup by planet and orbit #.

    then look for pairs, for each exporter if we find an importer on another platform at the same planet and orbit then create a link.

    todo maybe do importer states first and combine exporter states and linking into one step.

    linking naive:
    if importer has fluid in it, move some amount to exporter.
    if it doesnt, look in front of it for palletizer and in front of us for depalletizer.
    if all found, move some.

    todo better linking with linked inventories.
    

]]