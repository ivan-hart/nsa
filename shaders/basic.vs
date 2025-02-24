#version 460 core

layout ( location = 0 ) in vec3 aPos;
layout ( location = 1 ) in vec4 aColor;

layout ( location = 0 ) out vec4 fs_Color;

void main() {
    gl_Position = vec4(aPos, 1);
    fs_Color = aColor;
}
