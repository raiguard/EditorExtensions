local titlebar = {}

function titlebar.create(parent, name, data)
    local prefix = name .. '_'

    local titlebar_flow = parent.add {
        type = 'flow',
        name = prefix .. 'flow',
        style = 'titlebar_flow'
    }

    if data.adjust_for_border ~= false then
        titlebar_flow.style.top_margin = -3
    end

    if data.label then
        titlebar_flow.add {
            type = 'label',
            name = prefix .. 'label',
            style = 'frame_title',
            caption = data.label
        }
    end

    local filler = titlebar_flow.add {
        type = 'empty-widget',
        name = prefix .. 'filler',
        style = 'draggable_space_header'
    }
    filler.style.horizontally_stretchable = true
    if data.draggable then
        filler.drag_target = parent
        filler.style.natural_height = 24
        filler.style.minimal_width = 24
    end

    if data.buttons then
        filler.style.right_margin = 7
        local buttons = data.buttons
        for i=1, #buttons do
            titlebar_flow.add {
                type = 'sprite-button',
                name = prefix .. 'button_' .. buttons[i].name,
                style = 'close_button',
                tooltip = buttons[i].tooltip or nil,
                sprite = buttons[i].sprite,
                hovered_sprite = buttons[i].hovered_sprite or nil,
                clicked_sprite = buttons[i].clicked_sprite or nil
            }
        end
    end

    return titlebar_flow
end

return titlebar