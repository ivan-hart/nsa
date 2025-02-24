#version 460 core

layout ( location = 0 ) in vec3 aPos;
layout ( location = 1 ) in vec4 aColor;

uniform mat4 model;

layout ( location = 0 ) out vec4 fs_Color;

void main() {
    gl_Position = model * vec4(aPos, 1);
    fs_Color = aColor;
}
