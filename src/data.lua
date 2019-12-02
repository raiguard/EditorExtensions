infinity_tint = {r=1, g=0.5, b=1, a=1}

function apply_infinity_tint(t)
    t.tint = infinity_tint
    return t
end

function register_recipes(t, free_resource)
    for _,k in pairs(t) do
        data:extend{
            {
                type = 'recipe',
                name = 'ee_tool_'..k,
                ingredients = {},
                enabled = false,
                result = k
            }
        }
    end
end

require('prototypes/infinity-accumulator')
require('prototypes/infinity-chest')
require('prototypes/infinity-loader')
require('prototypes/infinity-misc')
require('prototypes/infinity-pole')
require('prototypes/infinity-robot')
require('prototypes/infinity-wagon')
require('prototypes/item-group')
require('prototypes/shortcut')
require('prototypes/style')

-- editor controller settings
local editor_controller = data.raw['editor-controller'].default
editor_controller.show_character_tab_in_controller_gui = true
editor_controller.show_infinity_filters_in_controller_gui = true
editor_controller.inventory_size = 150
editor_controller.render_as_day = false