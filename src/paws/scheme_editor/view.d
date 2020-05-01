module paws.scheme_editor.view;

import rpui.widgets.canvas.widget;
import rpui.view_component;
import rpui.view;
import rpui.widget;

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
}
