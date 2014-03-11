#version 150

in vec4 vertexPosition;
in vec2 texCoords;

smooth out vec2 varyingTexCoords;

void main()
{
    gl_Position = vertexPosition;
    varyingTexCoords = texCoords;
}
