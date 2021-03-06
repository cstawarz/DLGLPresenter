#version 150

uniform float screenWidth;
uniform float screenHeight;

//smooth in vec2 varyingPosition;

out vec4 outputColor;

void main()
{
    vec2 screenCenter = vec2(screenWidth/2.0, screenHeight/2.0);
    float dist = distance(screenCenter, gl_FragCoord.xy);
    float radius = 0.75 * (min(screenWidth, screenHeight) / 2.0);
    float delta = 1.0;
    if (dist > radius+delta)
        discard;
    outputColor.rgb = vec3(0.9, 0.9, 0.9);
    outputColor.a = 1.0 - smoothstep(radius-delta, radius+delta, dist);
}
