package nsa

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:strings"

import ecs "ecs"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

Camera :: struct {
	view:       glm.mat4,
	projection: glm.mat4,
}
camera: Camera

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

		mvp := transform.model * camera.projection * camera.view

		gl.UniformMatrix4fv(gl.GetUniformLocation(program, "mvp"), 1, gl.FALSE, &mvp[0][0])
		gl.BindVertexArray(renderable.vao)
		gl.DrawElements(gl.TRIANGLES, renderable.indices_count, gl.UNSIGNED_SHORT, nil)
	}
}

main :: proc() {
	ok := sdl.Init({.VIDEO})
	assert(ok)

	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfileFlag.CORE))
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 4)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 6)

	window := sdl.CreateWindow(
		"Nomad Space Agency",
		800,
		450,
		sdl.WINDOW_HIDDEN | sdl.WINDOW_OPENGL,
	)
	assert(window != nil);defer sdl.DestroyWindow(window)

	ctx := sdl.GL_CreateContext(window);defer sdl.GL_DestroyContext(ctx)
	assert(ctx != nil)

	gl.load_up_to(4, 6, sdl.gl_set_proc_address)

	gl.Enable(gl.DEPTH_TEST)
	gl.Viewport(0, 0, 800, 450)
	gl.ClearColor(0.1, 0.1, 0.3, 1.0)

	base_path := string(sdl.GetBasePath())

	vs_path := strings.concatenate({base_path, "shaders/basic.vs"}, context.allocator)
	fs_path := strings.concatenate({base_path, "shaders/basic.fs"}, context.allocator)

	program, p_ok := gl.load_shaders_file(vs_path, fs_path)
	if !p_ok {
		fmt.printfln("Failed to create shader program!")
	}

	delete(vs_path)
	delete(fs_path)

	camera = Camera {
		view       = glm.mat4{
            1, 0, 0, 0, 
            0, 1, 0, 0, 
            0, 0, 1, 0, 
            0, 0, 0, 1
        },
		projection = glm.mat4Perspective(glm.radians(f32(60)), 800.0 / 450.0, 0.001, 1000.0),
	}

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

	camera_input := Input{.W, .S, .A, .D, .SPACE, .C}

	sdl.ShowWindow(window)

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
			case .KEY_DOWN:
			}
		}

		if keys[camera_input.up] {
			camera.view[3].z += +1 * +0.016
		}
		if keys[camera_input.down] {
			camera.view[3].z += -1 * +0.016
		}
		if keys[camera_input.left] {
			camera.view[3].x += +1 * +0.016
		}
		if keys[camera_input.right] {
			camera.view[3].x += -1 * +0.016
		}
		if keys[camera_input.jump] {
			camera.view[3].y += -1 * +0.016
		}
		if keys[camera_input.crouch] {
			camera.view[3].y += +1 * +0.016
		}
		fmt.println(camera.view[3])


		// Rendering
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		render_system(&registry, program)
		sdl.GL_SwapWindow(window)

		sdl.Delay(16)
	}
}
