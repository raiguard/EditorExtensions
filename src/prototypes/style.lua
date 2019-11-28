-- STYLES
local styles = data.raw['gui-style'].default

styles['green_button'] = {
    type = 'button_style',
    parent = 'button',
    default_graphical_set = {
        base = {position = {68, 17}, corner_size = 8},
        shadow = default_dirt
    },
    hovered_graphical_set = {
        base = {position = {102, 17}, corner_size = 8},
        shadow = default_dirt,
        glow = default_glow(green_arrow_button_glow_color, 0.5)
    },
    clicked_graphical_set = {
        base = {position = {119, 17}, corner_size = 8},
        shadow = default_dirt
    },
    disabled_graphical_set = {
        base = {position = {85, 17}, corner_size = 8},
        shadow = default_dirt
    }
}

styles['green_icon_button'] = {
    type = 'button_style',
    parent = 'green_button',
    padding = 3,
    size = 28
}

styles['titlebar_flow'] = {
    type = 'horizontal_flow_style',
    direction = 'horizontal',
    horizontally_stretchable = 'on',
    vertical_align = 'center'
}

styles['invisible_horizontal_filler'] = {
    type = 'empty_widget_style',
    horizontally_stretchable = 'on'
}

styles['invisible_vertical_filler'] = {
    type = 'empty_widget_style',
    vertically_stretchable = 'on'
}

styles['entity_dialog_page_frame'] = {
    type = 'frame_style',
    parent = 'window_content_frame',
    minimal_width = 250,
    vertically_stretchable = 'on',
    horizontally_stretchable = 'on',
    left_padding = 8,
    top_padding = 6,
    right_padding = 6,
    bottom_padding = 6
}

styles['camera_frame'] = {
    type = 'frame_style',
    parent = 'window_content_frame',
    padding = 0
}

styles['stretchable_button'] = {
    type = 'button_style',
    parent = 'button',
    horizontally_stretchable = 'on'
}

styles['dropdown_button'].disabled_font_color = styles['button'].disabled_font_color
styles['dropdown_button'].disabled_graphical_set = styles['button'].disabled_graphical_set

styles['list_box_in_tabbed_pane'] = {
    type = 'list_box_style',
    parent = 'list_box',
    scroll_pane_style = {
        type = 'scroll_pane_style',
        parent = 'list_box_scroll_pane',
        vertical_scroll_policy = 'auto-and-reserve-space',
        graphical_set = {
            base = {
                position = {85, 0},
                corner_size = 8,
                center = {position = {42, 8}, size = 1},
                draw_type = 'outer'
            },
            shadow = default_inner_shadow
        }
    }
}

styles['vertically_centered_flow'] = {
    type='horizontal_flow_style',
    vertical_align = 'center'
}

styles['invalid_short_number_textfield'] = {
    type = 'textbox_style',
    parent = 'short_number_textfield',
    default_background = {
        base = {position = {248,0}, corner_size=8, tint=warning_red_color},
        shadow = textbox_dirt
    },
    active_background = {
        base = {position={265,0}, corner_size=8, tint=warning_red_color},
        shadow = textbox_dirt
    },
    disabled_background = {
        base = {position = {282,0}, corner_size=8, tint=warning_red_color},
        shadow = textbox_dirt
    }
}

styles['close_button_active'] = {
    type = 'button_style',
    parent = 'close_button',
    default_graphical_set = {
        base = {position = {272, 169}, corner_size = 8},
        shadow = {position = {440, 24}, corner_size = 8, draw_type = 'outer'}
    },
    hovered_graphical_set = {
        base = {position={369,17}, corner_size=8},
        shadow = {position = {440, 24}, corner_size = 8, draw_type = 'outer'}
    },
    clicked_graphical_set = {
        base = {position={352,17}, corner_size=8},
        shadow = {position = {440, 24}, corner_size = 8, draw_type = 'outer'}
    }
}

styles['virtual_slot_table_scroll_pane'] = {
    type = 'scroll_pane_style',
    parent = 'train_schedule_scroll_pane',
    background_graphical_set = {
        base = {
            position = {282,17},
            corner_size = 8,
            overall_tiling_vertical_size = 32,
            overall_tiling_horizontal_size = 32,
            overall_tiling_horizontal_padding = 4,
            overall_tiling_horizontal_spacing = 8,
            overall_tiling_vertical_spacing = 8,
            overall_tiling_vertical_padding = 4
        }
    }
}

-- ----------------------------------------------------------------------------------------------------
-- SPRITES

data:extend{
    {
        type = 'sprite',
        name = 'im-logo',
        filename = '__EditorExtensions__/graphics/gui/crafting-group.png',
        size = 128,
        flags = {'icon'}
    },
    {
        type = 'sprite',
        name = 'im-info-black-inline',
        filename = '__EditorExtensions__/graphics/gui/info-black-inline.png',
        size = {16,40},
        flags = {'icon'}
    },
    {
        type = 'sprite',
        name = 'im_pin',
        filename = '__EditorExtensions__/graphics/gui/pin.png',
        size = 32,
        flags = {'icon'}
    },
    {
        type = 'sprite',
        name = 'im_pin_black',
        filename = '__EditorExtensions__/graphics/gui/pin-black.png',
        size = 32,
        flags = {'icon'}
    },
    {
        type = 'sprite',
        name = 'im_no_default_on',
        filename = '__EditorExtensions__/graphics/gui/needs-restart-white.png',
        size = {16,40},
        scale = 0.5,
        flags = {'icon'},
        tint = green_arrow_button_glow_color
    },
    {
        type = 'sprite',
        name = 'im_no_default_off',
        filename = '__EditorExtensions__/graphics/gui/needs-restart-white.png',
        size = {16,40},
        scale = 0.5,
        flags = {'icon'},
        tint = red_arrow_button_glow_color
    }
}