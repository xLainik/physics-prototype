
if __name__ == "__main__":
    import pygame, json
    import os

    pygame.init()

    #screen = pygame.display.set_mode((256, 256), 0, 32)

##    offsets = [] # -> [(x_offset_frame_0, y_offset_frame_0), (x_offset_frame_1, y_offset_frame_1), (x_offset_frame_2, y_offset_frame_2), ...]

    # Read the input and determing # of anims and frames per ani
    # FORMAT FRAME NAME: "my_animation_1_0010.png"

    animations = {}

    MAX_WIDTH = 1

    for frame in os.listdir("input frames"):
        file_name = frame.split(".")[0] # remove the ".png"
        word_name = file_name.split("_")
        anim_frame = int(word_name.pop(-1))
        anim_name = "_".join(word_name)

        #print(anim_name, anim_frame)
        
        surf = pygame.image.load(os.path.join("input frames", frame))
        FRAME_SIZE = surf.get_size()
        if anim_name not in animations:
            animations[anim_name] = []
        animations[anim_name].append(surf)
        if len(animations[anim_name]) > MAX_WIDTH:
            MAX_WIDTH = len(animations[anim_name])

    # print(animations)
    # print(MAX_WIDTH)

    FRAME_WIDTH = FRAME_SIZE[0]
    FRAME_HEIGHT = FRAME_SIZE[1]

    sheet_surf = pygame.Surface((FRAME_WIDTH * MAX_WIDTH, FRAME_HEIGHT * len(animations)), pygame.SRCALPHA, 32)

    animation_count = 0
    for anim_name, frames in animations.items():
        for frame_index in range(len(frames)):
            rect = pygame.Rect(frame_index * FRAME_WIDTH, animation_count * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT)
            #sheet_surf.fill((193, 81, 227), rect) # BG purple color
            sheet_surf.blit(frames[frame_index], rect)
        animation_count = animation_count + 1

    pygame.image.save(sheet_surf, os.path.join("output results", "sheet.png"), "png")
  
##    surf = pygame.image.load(os.path.join("input frames", frame))
##    original_rect = surf.get_rect()
##    bounding_rect = surf.get_bounding_rect()
##
##    offsets.append(bounding_rect.topleft)
##    
##    pygame.image.save(cropped_surf, os.path.join("output results", frame), "png")

    

##    data = {}
##    data["offsets"] = offsets
        
##    with open(os.path.join("output results", "offsets.json"), "w") as outfile:
##        json.dump(data, outfile, indent=2)
##        outfile.close()
