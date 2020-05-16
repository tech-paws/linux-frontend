module paws.scheme_editor.view;

import std.stdio;

import rpui.widgets.canvas.widget;
import rpui.view_component;
import rpui.view;
import rpui.widget;
import rpui.events;
import rpui.math;

import paws.renderer;
import paws.backend;

final class SchemeEditorViewComponent : ViewComponent {
    View view;
    private CommandsHandler commandsHandler;

    @bindWidget Canvas canvas;

    this(View view, in string laytoutFileName, in string shortcutsFileName) {
        this.view = view;
        super(view, laytoutFileName, shortcutsFileName);
    }

    static SchemeEditorViewComponent create(View view) {
        return ViewComponent.createFromFile!(SchemeEditorViewComponent)(
            view,
            "map_editor.rdl"
        );
    }

    override void onCreate() {
        super.onCreate();

        this.commandsHandler = new CommandsHandler();
        canvas.canvasRenderer = new Renderer(commandsHandler);
    }

    @onMouseDownListener("canvas")
    void canvasOnMouseDown(in MouseDownEvent event) {
        if (!canvas.pointIsEnter(vec2i(event.x, event.y))) {
            return;
        }

        commandsHandler.pushSendOnTouchStart(
            event.x - canvas.absolutePosition.x,
            event.y - canvas.absolutePosition.y
        );
    }

    @onMouseUpListener("canvas")
    void canvasOnMouseUp(in MouseUpEvent event) {
        commandsHandler.pushSendOnTouchEnd(
            event.x - canvas.absolutePosition.x,
            event.y - canvas.absolutePosition.y
        );
    }

    @onMouseMoveListener("canvas")
    void canvasOnMouseMove(in MouseMoveEvent event) {
        if (!canvas.pointIsEnter(vec2i(event.x, event.y))) {
            return;
        }

        commandsHandler.pushSendOnTouchMove(
            event.x - canvas.absolutePosition.x,
            event.y - canvas.absolutePosition.y
        );
    }
}
