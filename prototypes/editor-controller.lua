local editor_controller = data.raw["editor-controller"].default
for name, setting in pairs(settings.startup) do
  if string.match(name, "ee%-controller") then
    editor_controller[string.gsub(name, "ee%-controller%-", "")] = setting.value
  end
end
