import bpy

map = {}
collisions = []

for group in bpy.data.groups:
    if group.name == "Collisions":
        # Found the collision Layer
        for obj in group.objects:
            print("Collecting ", obj.name)
            #for vert in obj.data.vertices:
            #    print(vert.co.x, vert.co.y, vert.co.z)
            new_box = {}
            new_box["name"] = "Box"
            new_box["location"] = str(obj.location.x) + "," + str(obj.location.y) + "," + str(obj.location.z)
            new_box["dimensions"] = str(obj.dimensions.x) + "," + str(obj.dimensions.y) + "," + str(obj.dimensions.z)
            collisions.append(new_box)
            
with open("test_map.txt",'w',encoding = 'utf-8') as file:
    file.write("Collisions \n")
    for coll in collisions:
        file.write(coll["name"] + " " + coll["location"] + " " + coll["dimensions"] + "\n")
