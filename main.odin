package nsa

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

GL_MAJOR :: 4
GL_MINOR :: 6

WIDTH :: 800
HEIGHT :: 450

main :: proc() {
	if !sdl.Init({.VIDEO}) {
		fmt.eprintln("Failed to init SDL!")
		return
	};defer sdl.Quit()

	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfileFlag.CORE))
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_MAJOR)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_MINOR)

	window := sdl.CreateWindow(
		"Nomad Space Agency",
		WIDTH,
		HEIGHT,
		sdl.WINDOW_HIDDEN | sdl.WINDOW_OPENGL,
	);defer sdl.DestroyWindow(window)
	if window == nil {
		fmt.eprintln("Failed to create SDL window!")
		return
	}

	ctx := sdl.GL_CreateContext(window);defer sdl.GL_DestroyContext(ctx)
	if ctx == nil {
		fmt.eprintln("Failed to create GL context")
		return
	}
	sdl.GL_MakeCurrent(window, ctx)

	gl.load_up_to(GL_MAJOR, GL_MINOR, sdl.gl_set_proc_address)

	base_path := string(sdl.GetBasePath())

	vs_src := load_shader_src_from_file(
		strings.concatenate({base_path, "shaders/basic.vs"}, context.allocator),
	)
	fs_src := load_shader_src_from_file(
		strings.concatenate({base_path, "shaders/basic.fs"}, context.allocator),
	)

	program, ok := gl.load_shaders_source(vs_src, fs_src);defer gl.DeleteProgram(program)
	if !ok {
		fmt.eprintln("Failed to load shader!")
		return
	}
	gl.UseProgram(program)

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)

	Vertex :: struct {
		pos:   glm.vec3,
		color: glm.vec4,
	}

	vertices := []Vertex {
		{{-0.5, -0.5, 0.0}, {1.0, 0.0, 0.0, 1.0}},
		{{0.5, -0.5, 0.0}, {0.0, 1.0, 0.0, 1.0}},
		{{0.5, 0.5, 0.0}, {0.0, 0.0, 1.0, 1.0}},
	}
	indices := []u16{0, 1, 2}

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(Vertex),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u16),
		raw_data(indices),
		gl.STATIC_DRAW,
	)

	gl.Viewport(0, 0, WIDTH, HEIGHT)
	gl.ClearColor(0.1, 0.1, 0.3, 1.0)

	sdl.ShowWindow(window)

	running := true

	loop: for running {
		e: sdl.Event
		for sdl.PollEvent(&e) {
			#partial switch e.type {
			case .QUIT:
				running = false
				break
			}
		}

		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)

		sdl.GL_SwapWindow(window)
	}
}

load_shader_src_from_file :: proc(path: string) -> string {
	data, ok := os.read_entire_file(path, context.allocator)
	if !ok {
		fmt.eprintfln("Error loading file %s", path)
	}
	return string(data)
}
