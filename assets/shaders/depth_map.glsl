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

    varying mat4 actualModelMatrix;

    attribute vec2 InstanceUVs;

    attribute vec4 ModelMat1;
    attribute vec4 ModelMat2;
    attribute vec4 ModelMat3;
    attribute vec4 ModelMat4;

    vec4 position( mat4 transform_projection, vec4 vertexPosition )
    {   
        vec4 screenPosition;
        //screenPosition = depthMVP * vertexPosition;

        actualModelMatrix = modelMatrix;
        if (isInstanced == true)
        {
            actualModelMatrix = mat4(ModelMat1, ModelMat2, ModelMat3, ModelMat4);
        }
        worldPosition = actualModelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

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