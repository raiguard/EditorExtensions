local recipe_names = {
    
}

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