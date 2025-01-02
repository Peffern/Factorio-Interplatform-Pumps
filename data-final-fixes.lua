-- TODO this should probably be in data.lua not data-final-fixes
-- but I couldn't figure out how to make it load after space-age

-- this is copied from an offshore pump but for space instead of water
local port_buildability_rules = {
    {
        area = {
            {
                -0.4,
                -0.4
            },
            {
                0.4,
                0.4
            }
        },
        colliding_tiles = {
            layers = {
                empty_space = true
            }
        },
        remove_on_collision = true,
        required_tiles = {
            layers = {
                ground_tile = true
            }
        }
    },
    {
        area = {
            {
                -1,
                -2
            },
            {
                1,
                -1
            }
        },
        colliding_tiles = {
            layers = {}
        },
        required_tiles = {
            layers = {
                empty_space = true
            }
        }
    }
}

-- this is copied from an asteroid collector
local port_collision_mask = {
    layers = {
        is_lower_object = true,
        is_object = true,
        train = true
    }
}

-- create port entities
local exporter_entity = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
exporter_entity.name = "exporter"
exporter_entity.minable.result = "exporter"
local importer_entity = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
importer_entity.name = "importer"
importer_entity.minable.result = "importer"

exporter_entity.tile_buildability_rules = port_buildability_rules
exporter_entity.collision_mask = port_collision_mask
importer_entity.tile_buildability_rules = port_buildability_rules
importer_entity.collision_mask = port_collision_mask

-- temporary graphics: keep pump graphics just recolor
for dir, _ in pairs(data.raw["offshore-pump"]["offshore-pump"].graphics_set.animation) do
    -- reddish for export, bluish for import
    exporter_entity.graphics_set.animation[dir].layers[1].tint = {1,0,0}
    importer_entity.graphics_set.animation[dir].layers[1].tint = {0,0,1}
end

-- fluid boxes
-- note on terminology: terms are relative to the user experience.
-- an EXPORT port is for sending items away from a space platform. So they accept items/fluid
-- an IMPORT port is for receiving items to a space platform. So they produce items/fluid.
-- since the fluid ones are pumps, the import ones don't need any changes; they already produce fluid.
-- the fluid exporter needs to have its direction reversed.

-- this is copied from offshore pump but with the directions reversed
exporter_entity.fluid_box = {
    pipe_connections = {
        {
            direction = 8,
            flow_direction = "input",
            position = {
                0,
                0
            }
        }
    },
    pipe_covers = {
        east = {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                },
                {
                    draw_as_shadow = true,
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                }
            }
        },
        north = {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                },
                {
                    draw_as_shadow = true,
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                }
            }
        },
        south = {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                },
                {
                    draw_as_shadow = true,
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                }
            }
        },
        west = {
            layers = {
                {
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                },
                {
                    draw_as_shadow = true,
                    filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
                    height = 128,
                    priority = "extra-high",
                    scale = 0.5,
                    width = 128
                }
            }
        }
    },
    production_type = "input",
    volume = 100
}

-- for items
-- the concept is that you put a palletizer in front of the export pump
-- and a depalletizer in front of the import pump.
-- those will have linked inventories instead of the pumps.
-- However, we want to make sure that they aren't just chests, since
-- chests don't work in space. These have to work in space definitionally, so we need
-- to make sure they don't cheese space storage designs. 
-- to accomplish this we make the palletizer input only and the depalletizer output only.

local palletizer_entity = table.deepcopy(data.raw["container"]["steel-chest"])
palletizer_entity.name = "palletizer"
palletizer_entity.minable.result = "palletizer"
palletizer_entity.flags = {
    "no-automated-item-removal", -- new flag
    "placeable-neutral", -- others from steel chest
    "player-creation"
}
palletizer_entity.picture.layers[1].tint = {1,0,0}
palletizer_entity.surface_conditions = { -- build only in space
    {
        max = 0,
        min = 0,
        property = "pressure"
    }
}
palletizer_entity.inventory_size = 1

local depalletizer_entity = table.deepcopy(data.raw["container"]["steel-chest"])
depalletizer_entity.name = "depalletizer"
depalletizer_entity.minable.result = "depalletizer"
depalletizer_entity.flags = {
    "no-automated-item-insertion", -- new flag
    "placeable-neutral",
    "player-creation"
}
depalletizer_entity.picture.layers[1].tint = {0,0,1}
depalletizer_entity.surface_conditions = { -- build only in space
    {
        max = 0,
        min = 0,
        property = "pressure"
    }
}
depalletizer_entity.inventory_size = 1

-- jet
-- the jet will ingest thruster fuel and consume it when moving between orbits
-- since the consumption will be done in script, all it needs to do here is
-- have the correct fluid boxes

local jet_entity = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
jet_entity.name = "jet"
jet_entity.minable.result = "jet"
-- it's 3x3, the furthest row of which should be on space tiles, the rest on solid ground
jet_entity.tile_buildability_rules = {
    {
        area = {
            {
                -1.4,
                -1.4
            },
            {
                1.4,
                0.4
            }
        },
        colliding_tiles = {
            layers = {
                empty_space = true
            }
        },
        remove_on_collision = true,
        required_tiles = {
            layers = {
                ground_tile = true
            }
        }
    },
    {
        area = {
            {
                -1,
                0.9
            },
            {
                1,
                1.1
            }
        },
        colliding_tiles = {
            layers = {}
        },
        required_tiles = {
            layers = {
                empty_space = true
            }
        }
    }
}
jet_entity.collision_mask = {
    layers = {
        is_lower_object = true,
        is_object = true,
        train = true
    }
}

-- 2 input flulid boxes, one for thruster one for oxidizer
-- even though we specify this in the recipe, we want it to show in the gui always
-- so we use filters
jet_entity.fluid_boxes = {
    {
        pipe_connections = {
            {
                direction = 0,
                flow_direction = "input",
                position = {
                    -1,
                    -1
                }
            }
        },
        pipe_covers = {
            east = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            },
            north = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            },
            south = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            },
            west = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            }
        },
        production_type = "input",
        volume = 100,
        filter= "thruster-fuel"
    },
    {
        pipe_connections = {
            {
                direction = 0,
                flow_direction = "input",
                position = {
                    1,
                    -1
                }
            }
        },
        pipe_covers = {
            east = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            },
            north = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            },
            south = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            },
            west = {
                layers = {
                    {
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
                        height = 128,
                        priority = "extra-high",
                        scale = 0.5,
                        width = 128
                    }
                }
            }
        },
        production_type = "input",
        volume = 100,
        filter= "thruster-oxidizer"
    }
} 
-- to hold dummy recipe
jet_entity.crafting_categories = {
    "jet"
}
jet_entity.placeable_position_visualization = table.deepcopy(data.raw["thruster"]["thruster"].placeable_position_visualization)


-- items

local exporter_item = table.deepcopy(data.raw["item"]["offshore-pump"])
exporter_item.name = "exporter"
exporter_item.place_result = "exporter"
local importer_item = table.deepcopy(data.raw["item"]["offshore-pump"])
importer_item.name = "importer"
importer_item.place_result = "importer"

local palletizer_item = table.deepcopy(data.raw["item"]["steel-chest"])
palletizer_item.name = "palletizer"
palletizer_item.place_result = "palletizer"
local depalletizer_item = table.deepcopy(data.raw["item"]["steel-chest"])
depalletizer_item.name = "depalletizer"
depalletizer_item.place_result = "depalletizer"

local jet_item = table.deepcopy(data.raw["item"]["chemical-plant"])
jet_item.name = "jet"
jet_item.place_result = "jet"   


-- recipes

-- dummy recipe to put in the jet (which is an assembler for dumb reasons)
local jet_category = table.deepcopy(data.raw["recipe-category"]["chemistry"])
jet_category.name = "jet"
jet_recipe = table.deepcopy(data.raw["recipe"]["heavy-oil-cracking"])
jet_recipe.category = "jet"
jet_recipe.enabled = true
jet_recipe.energy_required = 1000000000 -- this recipe should never run but just in case
jet_recipe.ingredients = {
    {
        amount = 50,
        name = "thruster-oxidizer",
        type = "fluid"
    },
    {
    amount = 50,
    name = "thruster-fuel",
    type = "fluid"
    }
}
jet_recipe.name = "jet"
jet_recipe.results = {}


data:extend{
    exporter_entity,
    importer_entity,
    palletizer_entity,
    depalletizer_entity,
    jet_entity,
    
    exporter_item,
    importer_item,
    palletizer_item,
    depalletizer_item,
    jet_item,

    jet_category,
    jet_recipe
}

