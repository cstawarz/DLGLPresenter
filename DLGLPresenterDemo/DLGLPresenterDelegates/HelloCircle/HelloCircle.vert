#version 150

uniform float screenWidth;
uniform float screenHeight;

in vec4 position;

//smooth out vec2 varyingPosition;

void main()
{
    vec4 scaledPosition = position;
    if (screenWidth > screenHeight) {
        scaledPosition.x *= screenHeight / screenWidth;
    } else if (screenHeight > screenWidth) {
        scaledPosition.y *= screenWidth / screenHeight;
    }
    gl_Position = scaledPosition;
    //varyingPosition = scaledPosition.xy;
}
