require('conf')

win = am.window({title=title,letterbox=true,width=1152,height=648})
Import = require('Modules.Import')
SceneHandler = require('Modules.SceneHandler')
win.scene = SceneHandler
listMenu = SceneHandler:load_scene('list')
