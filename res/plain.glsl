#version 330

uniform sampler2D colMap;
in vec2 coords;

void main(void)
{
    vec3 col = texture2D(colMap, coords.st*vec2(1, -1)).xyz;

    gl_FragColor = vec4(col, 1.0);
}

