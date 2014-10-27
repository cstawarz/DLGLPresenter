#version 150

in vec4 vertexPosition;

uniform float xMin, xMax, yMin, yMax;

smooth out vec2 varyingVertexPosition;

void main()
{
    gl_Position = vertexPosition;
    varyingVertexPosition = vertexPosition.xy;
}
