local gui = require("__flib__.gui")

gui.add_templates{
  titlebar_drag_handle = {type="empty-widget", style="draggable_space_header", style_mods={right_margin=5, height=24, horizontally_stretchable=true},
    save_as="drag_handle"},
  close_button = {type="sprite-button", style="close_button", style_mods={top_margin=2, width=20, height=20}, sprite="utility/close_white",
    hovered_sprite="utility/close_black", clicked_sprite="utility/close_black", mouse_button_filter={"left"}},
  entity_camera = function(entity, size, zoom, camera_offset, player_display_scale)
    return
      {type="frame", style="inside_deep_frame", children={
        {type="camera", style_mods={width=size, height=size}, position=util.position.add(entity.position, camera_offset), zoom=(zoom * player_display_scale)}
      }}
  end,
  vertically_centered_flow = {type="flow", style_mods={vertical_align="center"}},
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}},
    vertical = {type="empty-widget", style_mods={vertically_stretchable=true}}
  }
}