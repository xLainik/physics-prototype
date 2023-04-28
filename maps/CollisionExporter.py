import bpy
# Blender 2.93.16

CURRENT_DIRECTORY = "C:/Users/Erik/Desktop/project-somnus/maps"
EXPORT_MAP = 1
EXPORT_SECTION = 1

collisions = []


for collection in bpy.data.collections:
    collection_name = collection.name.split("_")
    if collection_name[0] != "SceneCollection":
        collection_section = int(collection_name[0])
        collection_type = collection_name[1]
    else:
        collection_section = None
        collection_type = None
    if collection_section == EXPORT_SECTION:
         if collection_type == "SectionBoundingBox":
             for obj in collection.objects:
                 new_boundingbox = "SectionBoundingBox" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z)
                 collisions.append(new_boundingbox)
         if collection_type == "Collisions":
             for obj in collection.objects:
                 print("Collecting ", obj.name)
                 total_verts = len(obj.data.vertices)
                 if total_verts == 8:
                     print("Box")
                     new_box = "Box" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z) + " " + str(obj.rotation_euler.x) + "," + str(obj.rotation_euler.y) + "," + str(obj.rotation_euler.z)
                     collisions.append(new_box)
                 elif total_verts <= 7:
                     top_verts = []
                     down_verts = []
                     for vert in obj.data.vertices:
                         # print(vert.co.x, vert.co.y, vert.co.z)
                         if vert.co.z == 0:
                             down_verts.append([vert.co.x, vert.co.y, vert.co.z])
                         elif vert.co.z == 1:
                             top_verts.append([vert.co.x, vert.co.y, vert.co.z])
                         print(len(top_verts), len(down_verts))
                     if len(top_verts) == len(down_verts):
                         print("Prism")
                     elif len(top_verts) == 2 and len(down_verts) == 4:
                         print("Regular_Ramp")
                         new_ramp = "Regular_Ramp" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z) + " " + str(obj.rotation_euler.x) + "," + str(obj.rotation_euler.y) + "," + str(obj.rotation_euler.z)
                         collisions.append(new_ramp)
                     elif len(top_verts) == 1 and len(down_verts) == 3:
                         print("Diagonal_Ramp")
                         new_diagonal_ramp = "Diagonal_Ramp" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z) + " " + str(obj.rotation_euler.x) + "," + str(obj.rotation_euler.y) + "," + str(obj.rotation_euler.z)
                         collisions.append(new_diagonal_ramp)
                     elif len(top_verts) == 3 and len(down_verts) == 4:
                         print("Diagonal_Ramp_Inner")
                         new_diagonal_ramp = "Diagonal_Ramp_Inner" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z) + " " + str(obj.rotation_euler.x) + "," + str(obj.rotation_euler.y) + "," + str(obj.rotation_euler.z)
                         collisions.append(new_diagonal_ramp)

         elif collection_type == "Doors":
             for obj in collection.objects:
                 print("Collecting ", obj.name)
                 new_door = "Door" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z) + " " + str(int(obj.data.get("door_index"))) + " " + str(int(obj.data.get("door_connect_section"))) + "," + str(int(obj.data.get("door_connect_index"))) + " " + str(obj.data.get("door_direction_x")) + "," + str(obj.data.get("door_direction_y"))
                 collisions.append(new_door)
        
         elif collection_type == "Tiles":
             for obj in collection.objects:
                 print("Exporting ", obj.name)
                 obj.select_set(True)
                 obj_path = str(CURRENT_DIRECTORY) + "/" + str(EXPORT_MAP) + "/sections/" + str(EXPORT_SECTION) + "/tiles.obj"
                 bpy.ops.export_scene.obj(filepath=obj_path, check_existing=True, use_selection=True, use_mesh_modifiers=True, use_edges=True, use_smooth_groups=False, use_smooth_groups_bitflags=False, use_normals=True, use_uvs=True, use_materials=False, use_triangles=False, use_nurbs=False, use_vertex_groups=False, use_blen_objects=True, group_by_object=False, group_by_material=False, keep_vertex_order=False, global_scale=1.0, axis_forward='X', axis_up='Z')
                 obj.select_set(False)
                 
            
with open(str(CURRENT_DIRECTORY) + "/" + str(EXPORT_MAP) + "/sections/" + str(EXPORT_SECTION) + "/collisions.dat",'w',encoding = 'utf-8') as file:
    for coll in collisions:
        file.write(coll + "\n")

