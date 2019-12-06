local styles = data.raw['gui-style'].default

-- --------------------------------------------------------------------------------
-- FRAME STYLES

styles['ee_ia_page_frame'] = {
    type = 'frame_style',
    parent = 'window_content_frame',
    vertically_stretchable = 'on',
    horizontally_stretchable = 'on',
    left_padding = 8,
    top_padding = 6,
    right_padding = 6,
    bottom_padding = 6
}

-- --------------------------------------------------------------------------------
-- SCROLLPANE STYLES

styles['ee_circuit_signals_scroll_pane'] =
{
  type = "scroll_pane_style",
  parent = "scroll_pane_with_dark_background_under_subheader",
  width = 308,
  height = 404,
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 4,
    overall_tiling_vertical_spacing = 12,
    overall_tiling_vertical_size = 28,
    overall_tiling_vertical_padding = 4
  }
}

-- --------------------------------------------------------------------------------
-- FLOW STYLES

styles['ee_titlebar_flow'] = {
    type = 'horizontal_flow_style',
    direction = 'horizontal',
    horizontally_stretchable = 'on',
    vertical_align = 'center'
}

styles['ee_vertically_centered_flow'] = {
    type='horizontal_flow_style',
    vertical_align = 'center'
}

styles['ee_entity_window_content_flow'] = {
    type = 'horizontal_flow_style',
    horizontal_spacing = 10
}

styles['ee_circuit_signals_flow'] = {
    type = 'horizontal_flow_style',
    horizontal_spacing = 12
}

-- --------------------------------------------------------------------------------
-- EMPTY WIDGET STYLES

styles['ee_invisible_horizontal_pusher'] = {
    type = 'empty_widget_style',
    horizontally_stretchable = 'on'
}

styles['ee_invisible_vertical_pusher'] = {
    type = 'empty_widget_style',
    vertically_stretchable = 'on'
}

-- --------------------------------------------------------------------------------
-- TEXTFIELD STYLES

styles['ee_slider_textfield'] = {
    type = 'textbox_style',
    parent = 'short_number_textfield',
    width = 50,
    horizontal_align = 'center',
    left_margin = 8
}

styles['ee_invalid_slider_textfield'] = {
    type = 'textbox_style',
    parent = 'ee_slider_textfield',
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

-- --------------------------------------------------------------------------------
-- BUTTON STYLES

styles['ee_disabled_dropdown_button'] = {
    type = 'button_style',
    parent = 'dropdown_button',
    disabled_font_color = styles['button'].disabled_font_color,
    disabled_graphical_set = styles['button'].disabled_graphical_set,
    left_padding = 8,
    width = 116
}

local modded_shadow_def = {
    position = {382, 107},
    corner_size = 12,
    top_outer_border_shift = 4,
    bottom_outer_border_shift = -4,
    left_outer_border_shift = 4,
    right_outer_border_shift = -4,
    draw_type = 'outer'
}

styles['ee_filter_slot_button_light'] = {
    type='button_style',
    parent='train_schedule_item_select_button',
    size = 36,
    padding = 0,
	default_graphical_set = {
		base = {border=4, position={2,738}, size=76},
		shadow = modded_shadow_def
    },
    hovered_graphical_set = {
        base = {border=4, position={82,738}, size=76},
        shadow = modded_shadow_def,
        glow = offset_by_2_rounded_corners_glow(default_glow_color)
    },
    clicked_graphical_set = {
        base = {border=4, position={162,738}, size=76},
        shadow = modded_shadow_def
    },
    disabled_graphical_set = {
		base = {border=4, position={2,738}, size=76},
		shadow = modded_shadow_def
    }
}

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

data:extend{
    {
        type = 'sprite',
        name = 'ee-logo',
        filename = '__EditorExtensions__/graphics/gui/crafting-group.png',
        size = 128,
        mipmap_count = 2,
        flags = {'icon'}
    }
}