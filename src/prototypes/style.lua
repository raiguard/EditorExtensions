local styles = data.raw["gui-style"].default

-- -----------------------------------------------------------------------------
-- BUTTON STYLES

styles.ee_disabled_dropdown_button = {
  type = "button_style",
  parent = "dropdown_button",
  disabled_font_color = styles.button.disabled_font_color,
  disabled_graphical_set = styles.button.disabled_graphical_set,
  left_padding = 8,
  width = 116
}

-- slightly smaller close button that looks WAY better ;)
styles.ee_frame_action_button = {
  type = "button_style",
  parent = "frame_action_button_no_border",
  size = 20,
  top_margin = 2
}

styles.ee_il_filter_button = {
  type = "button_style",
  parent = "statistics_slot_button",
  size =38
}

-- -----------------------------------------------------------------------------
-- FLOW STYLES

styles.ee_entity_window_content_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 12
}

-- -----------------------------------------------------------------------------
-- FRAME STYLES

styles.ee_ia_page_frame = {
  type = "frame_style",
  parent = "window_content_frame",
  vertically_stretchable = "on",
  horizontally_stretchable = "on",
  left_padding = 8,
  top_padding = 6,
  right_padding = 6,
  bottom_padding = 6
}

-- styles.ee_toolbar_frame = {
--   type = "frame_style",
--   parent = "subheader_frame",
--   horizontal_flow_style = {
--     type = "horizontal_flow_style",
--     horizontally_stretchable = "on",
--     vertical_align = "center"
--   }
-- }

-- -----------------------------------------------------------------------------
-- TEXTFIELD STYLES

styles.ee_slider_textfield = {
  type = "textbox_style",
  parent = "short_number_textfield",
  width = 50,
  horizontal_align = "center",
  left_margin = 8
}

styles.ee_invalid_slider_textfield = {
  type = "textbox_style",
  parent = "ee_slider_textfield",
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