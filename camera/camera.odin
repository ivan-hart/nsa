package camera;

import glm "core:math/linalg/glsl"

Camera :: struct {
	view:       glm.mat4,
	projection: glm.mat4,

    position: glm.vec3,
    yaw: f32,
    pitch: f32,
}

mouse_lock := false

get_instance :: proc() -> ^Camera {
    @(static) camera : Camera
    return &camera
}

init :: proc() {
    cam := get_instance()

    view := glm.mat4LookAt({0, 2, -2}, {0, 2, 0}, {0, 1, 0})

    projection := glm.mat4Perspective(glm.radians(f32(60.0)), 800.0 / 450.0, 0.001, 1000.0)

    cam.position = {0, 0, 3}  // Starting position
    cam.yaw = 90.0           // Face along negative Z-axis
    cam.pitch = 0.0
    cam.view = view
    cam.projection = projection
}
