uniform mat4 projectionMatrix; // light_camera
uniform mat4 modelMatrix;
uniform mat4 viewMatrix; // light_camera

varying vec4 worldPosition;
varying vec4 viewPosition;

uniform bool isInstanced;
varying vec2 instanceUVs;

#ifdef VERTEX

    uniform mat4 depthMVP;
    uniform bool isCanvasEnabled;

    attribute vec3 InstancePosition;
    attribute vec3 InstanceScale;
    attribute vec2 InstanceUVs;

    vec4 position( mat4 transform_projection, vec4 vertexPosition )
    {   
        vec4 screenPosition;
        //screenPosition = depthMVP * vertexPosition;

        if (isInstanced == true)
        {
            vertexPosition.xyz *= InstanceScale;
        }
        worldPosition = modelMatrix * vertexPosition;
        if (isInstanced == true)
        {
            worldPosition.xyz += InstancePosition;
        }
        viewPosition = viewMatrix * worldPosition;

        screenPosition = projectionMatrix * viewMatrix * worldPosition;

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
    }
#endif

#ifdef PIXEL
    vec4 effect( vec4 color, Image tex, vec2 texcoord, vec2 pixcoord )
    {   
        vec4 texcolor = Texel(tex, texcoord);

        // discards totally transparent colors (a > 0 are drawn)
        if (texcolor.a == 0.0)
        {
            discard;
        }
        
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
#endif