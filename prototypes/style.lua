local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.ee_disabled_dropdown_button = {
  type = "button_style",
  parent = "dropdown_button",
  disabled_font_color = styles.button.disabled_font_color,
  disabled_graphical_set = styles.button.disabled_graphical_set,
  left_padding = 8,
  width = 122,
}

styles.ee_il_filter_button = {
  type = "button_style",
  parent = "slot_button",
  size = 38,
}

-- DROPDOWN STYLES

styles.ee_ia_dropdown = {
  type = "dropdown_style",
  width = 122,
}

-- FRAME STYLES

styles.ee_inside_shallow_frame_for_entity = {
  type = "frame_style",
  parent = "inside_shallow_frame_with_padding",
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    horizontal_spacing = 8,
  },
}

-- LABEL STYLES

styles.ee_super_pump_per_second_label = {
  type = "label_style",
  parent = "bold_label",
  font = "default-semibold",
  left_margin = 4,
}

-- PROGRESSBAR STYLES

styles.ee_infinity_pipe_progressbar = {
  type = "progressbar_style",
  parent = "production_progressbar",
  bottom_margin = 2,
  horizontally_stretchable = "on",
}

styles.ee_infinity_pipe_progressbar_light_text = {
  type = "progressbar_style",
  parent = "ee_infinity_pipe_progressbar",
  filled_font_color = default_font_color,
}

-- TEXTFIELD STYLES

styles.ee_slider_textfield = {
  type = "textbox_style",
  width = 75,
  horizontal_align = "center",
  left_margin = 8,
}

styles.ee_invalid_slider_textfield = {
  type = "textbox_style",
  parent = "invalid_value_textfield",
  width = 75,
  horizontal_align = "center",
  left_margin = 8,
}

styles.ee_invalid_slider_value_textfield = {
  type = "textbox_style",
  parent = "slider_value_textfield",
  default_background = styles.invalid_value_textfield.default_background,
  active_background = styles.invalid_value_textfield.active_background,
}
