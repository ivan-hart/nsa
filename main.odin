package nsa

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

import ecs "ecs"
import win "window"
import camera "camera"

// Component Definitions
Input :: struct {
	up:    sdl.Scancode,
	down:  sdl.Scancode,
	left:  sdl.Scancode,
	right: sdl.Scancode,
	jump:  sdl.Scancode,
	crouch:sdl.Scancode,
}

Transform :: struct {
	model: glm.mat4,
}

Renderable :: struct {
	vao:           u32,
	indices_count: i32,
}

// TODO: add support for events?
// input_system :: proc(registry: ^ecs.Registry, event: sdl.Event, keys: [^]bool) {

// }

// Systems
render_system :: proc(registry: ^ecs.Registry, program: u32) {
	gl.UseProgram(program)
	for entity in registry.entities {
		transform := ecs.registry_get_component(registry, entity, Transform)
		renderable := ecs.registry_get_component(registry, entity, Renderable)
		if transform == nil || renderable == nil do continue

		cam := camera.get_instance()

		mvp := transform.model * cam.projection * cam.view

		gl.UniformMatrix4fv(gl.GetUniformLocation(program, "mvp"), 1, gl.FALSE, &mvp[0][0])
		gl.BindVertexArray(renderable.vao)
		gl.DrawElements(gl.TRIANGLES, renderable.indices_count, gl.UNSIGNED_SHORT, nil)
	}
}

update_camera :: proc(keys: [^]bool) {
	cam := camera.get_instance()

	if keys[sdl.Scancode.W] {
		cam.view[3].z += +1 * +0.016
	}
	if keys[sdl.Scancode.S] {
		cam.view[3].z += -1 * +0.016
	}
	if keys[sdl.Scancode.A] {
		cam.view[3].x += +1 * +0.016
	}
	if keys[sdl.Scancode.D] {
		cam.view[3].x += -1 * +0.016
	}
	if keys[sdl.Scancode.SPACE] {
		cam.view[3].y += -1 * +0.016
	}
	if keys[sdl.Scancode.LCTRL] {
		cam.view[3].y += +1 * +0.016
	}

	fmt.println(cam.view[3])
}

main :: proc() {
	win.init()
	camera.init()

	base_path := string(sdl.GetBasePath())

	vs_path := strings.concatenate({base_path, "assets/shaders/basic.vs"}, context.allocator)
	fs_path := strings.concatenate({base_path, "assets/shaders/basic.fs"}, context.allocator)

	program, p_ok := gl.load_shaders_file(vs_path, fs_path)
	if !p_ok {
		fmt.printfln("Failed to create shader program!")
	}

	delete(vs_path)
	delete(fs_path)

	// Create square geometry
	Vertex :: struct {
		pos:   glm.vec3,
		color: glm.vec4,
	}

	vertices := []Vertex {
		{{-0.5, -0.5, 0.0}, {1.0, 0.0, 0.0, 1.0}},
		{{0.5, -0.5, 0.0}, {0.0, 1.0, 0.0, 1.0}},
		{{0.5, 0.5, 0.0}, {0.0, 0.0, 1.0, 1.0}},
		{{-0.5, 0.5, 0.0}, {1.0, 1.0, 0.0, 1.0}},
	}
	indices := []u16{0, 1, 2, 2, 3, 0}

	// Create VAO/VBO/EBO
	vao, vbo, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(Vertex),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u16),
		raw_data(indices),
		gl.STATIC_DRAW,
	)

	// Vertex attributes
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.EnableVertexAttribArray(1)

	// Initialize ECS
	registry: ecs.Registry
	ecs.registry_init(&registry)
	defer ecs.registry_destroy(&registry)

	// Create square entity
	square := ecs.registry_create_entity(&registry)
	ecs.registry_add_component(&registry, square, Transform{glm.mat4(1)})
	ecs.registry_add_component(&registry, square, Renderable{vao, i32(len(indices))})

	win.show()

	// Main loop
	running := true
	for running {
		keys := sdl.GetKeyboardState(nil)

		// Event handling
		e: sdl.Event
		for sdl.PollEvent(&e) {
			#partial switch e.type {
			case .QUIT:
				running = false
				break
			}
		}
		update_camera(keys)

		// Rendering
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		render_system(&registry, program)
		win.swap()

		sdl.Delay(16)
	}
}
