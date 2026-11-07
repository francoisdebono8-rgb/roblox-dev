import bpy
from pathlib import Path
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(out/'Chidori_R15.blend'))
s=bpy.context.scene
s.render.image_settings.file_format='PNG'
s.render.filepath=str(out/'frames'/'animation_')
s.render.resolution_percentage=100
bpy.ops.render.render(animation=True)
