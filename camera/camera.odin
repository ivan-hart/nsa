package camera;

import glm "core:math/linalg/glsl"

Camera :: struct {
	view:       glm.mat4,
	projection: glm.mat4,
}

get_instance :: proc() -> ^Camera {
    @(static) camera : Camera
    return &camera
}

init :: proc() {
    cam := get_instance()

    view : glm.mat4
    view[3].xyzw = glm.vec4{0, 0, 0, 1}
    view[1].xyzw = glm.vec4{1, 1, 1, 1}

    projection := glm.mat4Perspective(glm.radians(f32(60.0)), 800.0 / 450.0, 0.001, 1000.0)

    cam = &Camera {
        view = view,
        projection = projection
    }
}
