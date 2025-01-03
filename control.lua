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

    -- reverse lookup to see what platforms are at what orbit on what planets
    -- index by surface (planet?) -> orbit # -> list of platform unit #s.
    storage.space_location_lookups = {}
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
                -- initialize platform orbit state for this platform
                entity = player.opened
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
                -- initialize importer/exporter state for this entity
                entity = player.opened
            }
        end

        -- since it's a signal button, elem_value will be the signal data and we can store it directly in the table
        storage[storage_key][unit_number % shard_count][unit_number].port_id_signal = event.element.elem_value
    
    end
end

-- general on tick handler.
function tick_handler(event)
    local shard = event.tick % shard_count -- which slice of machines are we processing on this tick

    -- platform orbit stuff
    -- any platforms that we dont know about cant have an orbit signal set. therefore they cant change their orbit
    -- therefore they cant link and transfer items/fludis so we dont care about them and can skip.

    -- iterate over the ones we do know about

    for unit_number, platform_state in pairs(storage.platform_orbit_states[shard]) do
        local entity = platform_state.entity -- get the platform hub entity for this entry
        local platform = entity.surface.platform

        if platform and platform.state == defines.space_platform_state.waiting_at_station then
            local signal_value = 0 -- treat no signal like 0. you have to keep the signal for the whole time you're in transit if you want to get anywhere.
            local destination_signal = platform_state.orbit_destination_signal
            if destination_signal then
                -- destination signal is something like {type="item",name="thruster"}.
                -- check the value of this signal
                local circuit_network = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
                if not circuit_network then circuit_network = entity.get_circuit_network(defines.wire_connector_id.circuit_green) end
                

                if circuit_network then
                    signal_value = circuit_network.get_signal(destination_signal)
                end
            end

            local space_location = platform.space_location.name
            if not storage.space_location_lookups[space_location] then storage.space_location_lookups[space_location] = {} end -- create if not exists

            
            -- first special case. if you ever don't have a destination or whatever, all progress is erased and you go to 0/"high" orbit.
            if signal_value == 0 then
                -- TODO decrement
                storage.platform_orbit_states[shard][unit_number].current_orbit_number = 0
                storage.platform_orbit_states[shard][unit_number].orbit_transit_progress = 0
            elseif signal_value ~= platform_state.current_orbit_number then
            -- now read current orbit location and progress from state.
            -- if current == signal_value then we are there or en route.
            -- we dont do progress updates here, that happens in the jet handler.
            -- enough to mark it as current destination/location.
            -- in order to do that it has to be free.
            -- TODO actually do this
            end
        end


        
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

script.on_event(defines.events.on_tick, tick_handler)

script.on_init(setup)

-- everything should be in place
--[[

    so then plan for on_tick is:

    for space platforms, see if they have a set signal.
    if yes read the corresponding signal, and get the value.
    if it isnt matching the current orbit position then try to put us in transit.
        
    i.e. make sure we dont have 2 already there or in transit. then set us in transit and set progress to 0.
        
    also handle cancels, i.e. if it does match and we arent stopped, then stop.
    handle case where we turn around but someone took our spot. do we hold both? do we swap the progress bar around?
    the solution for this is that if you are waiting you are always in the 0 orbit.
    you can be in one of the following states:
    - 0 orbit (idle)
    - N orbit (idle / maybe linked and transferring)
    - traveling to N orbit (this counts as N for the 2 limit)
    - waiting to travel to N orbit (this counts as 0).
    
    the key is that 0 isnt an orbit and so going to it is free. 1->0->2 is the same as 1->2 in terms of fuel cost.
    so every tick we read the signal.
    if 0 go instantly to 0 and idle.
    if some N (N!= 0) and we are idle at N do nothing.
    if N and we are en route to N do nothing.
    if N and we are at 0
        if N is open then go to traveling-to-N state (0% progress)
        if N is closed then stay at 0 and go to waiting-for-N state.
    if N and we are at some M (N != M, M!= 0)
        if M is open then go to traveling-to-N state (0% progress)
        if N is closed then go instantly to 0 and go to waiting-for-N state.
   if N and we are en route to M
        if N is open then go to traveling-to-N state (reset progress to 0% progress)
        if N is closed then go instantly to 0 and go to waiting-for-N state (lose progress).
        
    this setup means that if we try to change dests and get stuck we drop back to 0. 
    in fact, we dont even need a waiting state, since by definition we can have as many as we want and waiting

    for thrusters, if were currently in transit then try to do a tick.
    that means, drain fuel + oxidizer and and tick up the progress bar.
    include completion, if it fills then we go to stopped and not in transit an
    y more.

    
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

    todo investigate linked inventories / fluidboxes and see if there's a better way
    

]]