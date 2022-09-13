
#ifdef VERTEX
    vec4 position(mat4 transform_projection, vec4 vertex_position)
    {
        vec4 screenPosition;
        screenPosition = vec4(transform_projection * vertex_position);
        screenPosition.y *= -1.0;
        return screenPosition;
    }
#endif

#ifdef PIXEL
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        // float depthValue;
        // depthValue = (shadow2DProj(depthmap, vec4(screen_coords, 0.0, 1.0)).r);
        // // or textureLod(tex, uv, 0.)
        // return vec4(vec3(screen_coords.x, screen_coords.y, 1.0), 1.0);

        vec4 texcolor = Texel(tex, texture_coords);
        return vec4(vec3(mod(texcolor*256.0,1.0)),1.0);
    }
#endif