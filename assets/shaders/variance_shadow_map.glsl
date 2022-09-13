uniform Image shadowMapImage;

#ifdef PIXEL
    vec4 effect( vec4 color, Image tex, vec2 texcoord, vec2 pixcoord )
        {   
            float depthValue = Texel(shadowMapImage, texcoord).r;
            return vec4(depthValue, depthValue*depthValue, 0.0, 1.0);
        }
#endif