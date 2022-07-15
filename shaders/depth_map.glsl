uniform mat4 projectionMatrix; // light_camera
uniform mat4 modelMatrix;
uniform mat4 viewMatrix; // light_camera

varying vec4 worldPosition;
varying vec4 viewPosition;

#ifdef VERTEX

    uniform mat4 depthMVP;
    uniform bool isCanvasEnabled;

    uniform bool animated;

    attribute vec4 VertexWeight;
    attribute vec4 VertexBone;
    uniform mat4 u_pose[100]; //100 bones crashes web version, only set to whats absolutely necesary


    vec4 position( mat4 transform_projection, vec4 vertexPosition )
    {   
        if (animated == true)
        {
            mat4 skeleton = u_pose[int(VertexBone.x*255.0)] * VertexWeight.x +
                u_pose[int(VertexBone.y*255.0)] * VertexWeight.y +
                u_pose[int(VertexBone.z*255.0)] * VertexWeight.z +
                u_pose[int(VertexBone.w*255.0)] * VertexWeight.w;
            vertexPosition = skeleton * vertexPosition;
        };

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