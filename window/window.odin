package window;

import "core:fmt"

import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

Window :: struct {
    sdl_window : ^sdl.Window,
    gl_ctx : sdl.GLContext,
    width, height : i32
}

get_instance :: proc() -> ^Window {
    @(static) window : Window
    return &window
}

init :: proc(title : cstring, width, height: i32) -> bool {
    window := get_instance()

    if !sdl.Init({.VIDEO}) {
        sdl.Log("Failed to init SDL!: %s", sdl.GetError())
        return false;
    }

    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLProfileFlag.CORE))
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 4);
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 6);

    sdl_window := sdl.CreateWindow(title, width, height, sdl.WINDOW_HIDDEN | sdl.WINDOW_OPENGL)
    if sdl_window == nil {
        sdl.Log("Failed to create SDL_Window!: %s", sdl.GetError())
        sdl.Quit()
        return false;
    }

    ctx := sdl.GL_CreateContext(sdl_window)
    if ctx == nil {
        sdl.Log("Failed to create the OpenGL context!: %s", sdl.GetError())
        sdl.DestroyWindow(sdl_window);
        sdl.Quit();
        return false;
    }

    gl.load_up_to(4, 6, sdl.gl_set_proc_address)

    gl.Enable(gl.DEPTH_TEST)
	gl.Viewport(0, 0, width, height)
	gl.ClearColor(0.1, 0.1, 0.3, 1.0)

    window.sdl_window = sdl_window
    window.gl_ctx = ctx
    window.width = width
    window.height = height

    return true
}

hide :: proc() {
    window := get_instance()

    sdl.HideWindow(window.sdl_window)
}

show :: proc() {
    window := get_instance()

    sdl.ShowWindow(window.sdl_window)
}

close :: proc() {
    window := get_instance()

    sdl.GL_DestroyContext(window.gl_ctx)
    sdl.DestroyWindow(window.sdl_window)
    sdl.Quit()
}

clear :: proc() {
    win := get_instance()

    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

swap :: proc() {
    window := get_instance()

    sdl.GL_SwapWindow(window.sdl_window)
}
