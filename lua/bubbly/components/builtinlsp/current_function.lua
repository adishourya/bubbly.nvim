local bubble_factory = require'bubbly.factories.bubble'

return function(inactive)
   if inactive then return '' end
   local data = vim.b.bubbly_current_function
   return bubble_factory{{
         data = data,
         color = vim.g.bubbly_colors.builtinlsp.current_function,
         style = vim.g.bubbly_styles.builtinlsp.current_function,
   }}
end

