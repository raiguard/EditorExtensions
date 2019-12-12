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

styles['ee_toolbar_frame'] = {
  type = 'frame_style',
  parent = 'subheader_frame',
  horizontal_flow_style = {
    type = 'horizontal_flow_style',
    horizontally_stretchable = 'on',
    vertical_align = 'center'
  }
}

styles['ee_toolbar_frame_for_switch'] = {
  type = 'frame_style',
  parent = 'ee_toolbar_frame',
  horizontal_flow_style = {
    type = 'horizontal_flow_style',
    horizontally_stretchable = 'on',
    left_padding = 8,
    vertical_align = 'center'
  }
}

styles['ee_current_signal_frame'] = {
  type = 'frame_style',
  graphical_set = {
    base = {
      center = {position={76,8}, size=1},
      draw_type = "outer"
    }
  },
  horizontal_flow_style = {
    type = 'horizontal_flow_style',
    horizontally_stretchable = 'on',
    vertical_align = 'center'
  }
}

-- --------------------------------------------------------------------------------
-- SCROLLPANE STYLES

styles['signal_scroll_pane'] = {
  type = 'scroll_pane_style',
  parent = 'train_schedule_scroll_pane',
  padding = 0,
  minimal_width = 252, -- six columns + scrollbar
  height = 160, -- four rows
  extra_right_padding_when_activated = -12,
  graphical_set = {
    base = {
      position = {17,0},
      corner_size = 8,
      center = {position={42,8}, size=1},
      top = {},
      left_top = {},
      right_top = {},
      -- redefine bottom to be lighter so it transitions into the bottom pane seamlessly
      bottom = {position={93,9}, size={1,8}},
      draw_type = 'outer'
    },
    shadow = {
      position = {183,128},
      corner_size = 8,
      tint = default_shadow_color,
      scale = 0.5,
      draw_type = 'inner',
      -- overwrite the bottom to not have a shadow at all
      left_bottom = {},
      bottom = {},
      right_bottom = {}
    }
  },
  background_graphical_set = {
    base = {
      position = {282, 17},
      corner_size = 8,
      overall_tiling_horizontal_padding = 4,
      overall_tiling_horizontal_size = 32,
      overall_tiling_horizontal_spacing = 8,
      overall_tiling_vertical_padding = 4,
      overall_tiling_vertical_size = 32,
      overall_tiling_vertical_spacing = 8,
      custom_horizontal_tiling_sizes = {32, 32, 32, 32, 32, 32} -- to avoid little bumps in the scrollbar area
    }
  }
}

styles['signal_slot_table'] = {
  type = 'table_style',
  parent = 'slot_table',
  horizontal_spacing = 0,
  vertical_spacing = 0
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

styles['filter_slot_button_smaller'] = {
  type = 'button_style',
  parent = 'quick_bar_slot_button',
  -- 0.18
  -- parent = 'filter_slot_button',
  size = 38
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
  },
  {
    type = 'sprite',
    name = 'ee-time',
    filename = '__EditorExtensions__/graphics/gui/time-alt.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  },
  {
    type = 'sprite',
    name = 'ee-sort',
    filename = '__EditorExtensions__/graphics/gui/sort.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  }
}