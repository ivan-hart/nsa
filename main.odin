package nsa

// core library imports
import "core:fmt"

// vendor library imports
import sdl "vendor:sdl3"

// project package imports
import win "window"

// main function or better known as the entry point
main :: proc() {
	// initalizes the window and checks to see if it failed the init proccess
	if !win.init("NSA Dev Window", 800, 450) 
	{
		fmt.eprintfln("Failed to initalize window!")
	};defer win.close()

	// shows the window as it is hidden by default
	win.show()

	// the variable we'll be using to see if we can loop again
	running := true

	// the main loop of the application
	for running 
	{
		// the event variable we'll be polling on
		e: sdl.Event
		for sdl.PollEvent(&e) 
		{
			#partial switch e.type {
				// checks to see if SDL has thrown out a quit event and tells the application to stop looping
				case .QUIT:
					running = false
					break
			}
		}
		// clears the screen each frame
		win.clear()

		// swaps the back buffers of the window each fram
		win.swap()
	}
}
