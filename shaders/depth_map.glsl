uniform mat4 projectionMatrix; // light_camera
uniform mat4 modelMatrix;
uniform mat4 viewMatrix; // light_camera

varying vec4 worldPosition;
varying vec4 viewPosition;

#ifdef VERTEX

    uniform mat4 depthMVP;
    uniform bool isCanvasEnabled;

    vec4 position( mat4 transform_projection, vec4 vertexPosition )
    {   

        vec4 screenPosition;
        //screenPosition = depthMVP * vertexPosition;

        worldPosition = modelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;

        screenPosition = projectionMatrix * viewMatrix * modelMatrix * vertexPosition;

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
    }
#endif

#ifdef PIXEL
    vec4 effect( vec4 color, Image tex, vec2 texcoord, vec2 pixcoord )
    {   
        
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
#endif