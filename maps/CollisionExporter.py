import bpy

EXPORT_SECTION = 1

collisions = []

for group in bpy.data.groups:
    group_name = group.name.split("_")
    group_section = int(group_name[0])
    group_type = group_name[1]
    if group_section == EXPORT_SECTION:
        if group_type == "SectionBoundingBox":
            for obj in group.objects:
                new_boundingbox = "SectionBoundingBox" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z)
                collisions.append(new_boundingbox)
        if group_type == "Collisions":
            for obj in group.objects:
                print("Collecting ", obj.name)
                #for vert in obj.data.vertices:
                #    print(vert.co.x, vert.co.y, vert.co.z)
                new_box = "Box" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z)
                collisions.append(new_box)
        elif group_type == "Doors":
            for obj in group.objects:
                print("Collecting ", obj.name)
                new_door = "Door" + " " + str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z) + " " + str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z) + " " + str(int(obj.data.get("door_index"))) + " " + str(int(obj.data.get("door_connect_section"))) + "," + str(int(obj.data.get("door_connect_index"))) + " " + str(obj.data.get("door_direction_x")) + "," + str(obj.data.get("door_direction_y"))
                collisions.append(new_door)
            
with open("sections/" + str(EXPORT_SECTION) + "/collisions.dat",'w',encoding = 'utf-8') as file:
    for coll in collisions:
        file.write(coll + "\n")
