uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;

varying vec3 normal;

#ifdef VERTEX
    uniform bool isCanvasEnabled;

    attribute vec3 VertexNormal;

    varying vec4 worldPosition;
    varying vec4 viewPosition;
    varying vec4 screenPosition;
    varying vec3 vertexNormal;
    varying vec4 vertexColor;

    vec4 position(mat4 transformProjection, vec4 vertexPosition) {
        worldPosition = modelMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;

        vertexNormal = VertexNormal;
        vertexColor = VertexColor;

        normal = VertexNormal;

        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }

        return screenPosition;
        }
#endif

#ifdef PIXEL
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
    {
        vec4 texcolor = Texel(tex, texcoord);

        if (texcolor.a == 0.0)
        {
            discard;
        }

        return texcolor;
    }
#endif

