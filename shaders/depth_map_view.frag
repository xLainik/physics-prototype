
uniform sampler2DShadow depthmap;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    float depthValue;
    depthValue = (shadow2DProj(depthmap, vec4(screen_coords, 0.0, 1.0)).r);
    // or textureLod(tex, uv, 0.)
    return vec4(vec3(1.0, screen_coords.x/1280, screen_coords.y/1280), 1.0);
}
