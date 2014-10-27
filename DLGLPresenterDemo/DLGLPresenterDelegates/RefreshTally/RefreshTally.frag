#version 150

in vec2 varyingVertexPosition;

out vec4 outputColor;

uniform float xMin, xMax, yMin, yMax;

void main()
{
    if (varyingVertexPosition.x < xMin ||
        varyingVertexPosition.x > xMax ||
        varyingVertexPosition.y < yMin ||
        varyingVertexPosition.y > yMax)
    {
        discard;
    }
    
    outputColor = vec4(0.0f, 0.0f, 0.0f, 1.0f);
}
