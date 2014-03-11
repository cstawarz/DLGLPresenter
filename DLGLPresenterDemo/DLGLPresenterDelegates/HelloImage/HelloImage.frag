#version 150

uniform sampler2D colorMap;

in vec2 varyingTexCoords;

out vec4 fragColor;

void main()
{
    fragColor = texture(colorMap, varyingTexCoords);
}
