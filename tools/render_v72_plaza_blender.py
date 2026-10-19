"""Headless Blender depth-buffer render of a recorded native geometry cutaway."""
import json
import sys
from pathlib import Path
import bpy
from mathutils import Vector

arguments = sys.argv[sys.argv.index('--') + 1:]
source, target, view = arguments
spec = json.loads(Path(source).read_text())
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.studio_light = 'paint.sl'
scene.display.shading.color_type = 'OBJECT'
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.cavity_type = 'BOTH'
scene.display.shading.curvature_ridge_factor = 1.0
scene.display.shading.curvature_valley_factor = .65
scene.display.shading.background_type = 'WORLD'
scene.world.color = (.014, .021, .033)
scene.view_settings.view_transform = 'Standard'
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = target
scene.display.render_aa = '32'
for index, group in enumerate(spec['groups']):
    mesh = bpy.data.meshes.new(f'NativeGeometry{index}')
    mesh.from_pydata(group['vertices'], [], group['faces'])
    mesh.update()
    obj = bpy.data.objects.new(f'NativeGeometry{index}', mesh)
    bpy.context.collection.objects.link(obj)
    obj.color = tuple(group['color']) + (1.,)
camera_data = bpy.data.cameras.new('ReviewCamera')
camera = bpy.data.objects.new('ReviewCamera', camera_data)
bpy.context.collection.objects.link(camera)
scene.camera = camera
camera_data.type = 'ORTHO'
views = {
    'market': ((0, -70, 130), (0, 0, 1), 263, 1740, 510),
    'lab': ((13, 3, 12), (0, 21, 1.8), 22, 855, 500),
    'portal': ((93, -25, 18), (119, 0, 9), 39, 855, 500),
}
position, target_point, scale, width, height = views[view]
camera.location = position
direction = Vector(target_point) - camera.location
camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
camera_data.ortho_scale = scale
scene.render.resolution_x = width
scene.render.resolution_y = height
bpy.ops.render.render(write_still=True)
