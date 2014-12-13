#version 330

uniform float width;
uniform float height;

out vec4 outCol;
in vec2 coords;

void main(void)
{
    float x = gl_FragCoord.x/width;
    float y = gl_FragCoord.y/width;
    outCol = vec4(abs(coords.x), abs(coords.y), x*y, 1.0);
}
