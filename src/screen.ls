

# screen = blessed.screen()

# box-data = {
#   top: '0%',
#   left: '50%',
#   width: '50%',
#   height: '100%',
#   tags: true,
#   border: {
#     type: 'line'
#   },
#   style: {
#     fg: 'white',
#     bg: 'black',
#     border: {
#       fg: '#f0f0f0'
#     },
#     hover: {
#       bg: 'green'
#     }
#   }
# }

# box = blessed.box(box-data)
# box.key 'x', ->
#     process.exit()

# screen.append(box)

# log = -> 
#     box.setContent(it)
#     screen.render()