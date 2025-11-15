#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <time.h>

enum {
    TEXT_X = 20,
    TEXT_Y = 20,

    RECT_X = 20,
    RECT_Y = 20,
    RECT_WIDTH = 10,
    RECT_HEIGHT = 10,

    WIN_X = 10,
    WIN_Y = 10,
    WIN_WIDTH = 1200,
    WIN_HEIGHT = 800,
    WIN_BORDER = 1
};

int main(void) {
    Display *display;
    Window window;
    XEvent event;
    int screen;

    const char *msg = "Hello, World!";

    display = XOpenDisplay(NULL);
    
    if (display == NULL) {
        fprintf(stderr, "Cannot open display\n");
        exit(1);
    }

    screen = DefaultScreen(display);

    window = XCreateSimpleWindow(
        display, 
        RootWindow(display, screen), 
        WIN_X, WIN_Y, WIN_WIDTH, WIN_HEIGHT, WIN_BORDER,
        BlackPixel(display, screen),
        WhitePixel(display, screen)
    );

    XSelectInput(display, window, ExposureMask | KeyPressMask);

    XMapWindow(display, window);

    while (True) {
        XNextEvent(display, &event);
        
        if (event.type == Expose) {
            XFillRectangle(display, window, DefaultGC(display, screen), RECT_X, RECT_Y, RECT_WIDTH, RECT_HEIGHT);
            XDrawString(display, window, DefaultGC(display, screen), TEXT_X, TEXT_Y, msg, strlen(msg));
        }
        if (event.type == KeyPress)
            break;
    }

    XCloseDisplay(display);
    return 0;
}