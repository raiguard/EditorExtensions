-- ----------------------------------------------------------------------------------------------------
-- EDITOR EXTENSIONS PROTOTYPES

infinity_tint = {r=1, g=0.5, b=1, a=1}
function apply_infinity_tint(t)
    t.tint = infinity_tint
    return t
end

infinity_chest_data = {
    ['active-provider'] = {s=0, t={218,115,255}, o='ab'},
    ['passive-provider'] = {s=0, t={255,141,114}, o='ac'},
    ['storage'] = {s=1, t={255,220,113}, o='ad'},
    ['buffer'] = {s=30, t={114,255,135}, o='ae'},
    ['requester'] = {s=30, t={114,236,255}, o='af'}
}
tesseract_chest_data = {
    [''] = {t={255,255,255}, o='ba'},
    ['passive-provider'] = {t={255,141,114}, o='bb'},
    ['storage'] = {t={255,220,113}, o='bc'}
}

-- editor controller settings
local editor_controller = data.raw['editor-controller'].default
editor_controller.show_character_tab_in_controller_gui = true
editor_controller.show_infinity_filters_in_controller_gui = true
editor_controller.inventory_size = 150
editor_controller.render_as_day = false