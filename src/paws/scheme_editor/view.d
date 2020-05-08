module paws.scheme_editor.view;

import std.stdio;

import rpui.widgets.canvas.widget;
import rpui.view_component;
import rpui.view;
import rpui.widget;
import rpui.events;
import rpui.math;

import paws.renderer;

final class SchemeEditorViewComponent : ViewComponent {
    @bindWidget Canvas canvas;

    this(View view, in string laytoutFileName, in string shortcutsFileName) {
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
        canvas.canvasRenderer = new Renderer();
    }

    @onMouseDownListener("canvas")
    void canvasOnMouseDown(in MouseDownEvent event) {
        if (!canvas.pointIsEnter(vec2i(event.x, event.y))) {
            return;
        }
    }

    @onMouseUpListener("canvas")
    void canvasOnMouseUp(in MouseUpEvent event) {
        if (!canvas.pointIsEnter(vec2i(event.x, event.y))) {
            return;
        }
    }

    @onMouseMoveListener("canvas")
    void canvasOnMouseMove(in MouseMoveEvent event) {
        if (!canvas.pointIsEnter(vec2i(event.x, event.y))) {
            return;
        }
    }
}
