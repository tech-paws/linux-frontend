module paws.debug_service.view;

import rpui.view_component;
import rpui.view;
import rpui.widget;
import rpui.widgets.tab_button.widget;

final class DebugViewComponent : ViewComponent {
    @bindWidget Widget panelDebug;
    @bindWidget TabButton tabButtonDebug;
    @bindWidget TabButton tabButtonProfile;

    this(View view, in string laytoutFileName, in string shortcutsFileName) {
        super(view, laytoutFileName, shortcutsFileName);
    }

    static DebugViewComponent create(View view) {
        return ViewComponent.createFromFileWithShortcuts!(DebugViewComponent)(view, "debug.rdl");
    }

    @shortcut("Debug.debug")
    void debugLayout() {
        if (panelDebug.isVisible && tabButtonDebug.checked) {
            panelDebug.isVisible = false;
        }
        else {
            panelDebug.isVisible = true;
            tabButtonDebug.checked = true;
            tabButtonProfile.checked = false;
        }
    }

    @shortcut("Debug.profile")
    void profileLayout() {
        if (panelDebug.isVisible && tabButtonProfile.checked) {
            panelDebug.isVisible = false;
        }
        else {
            panelDebug.isVisible = true;
            tabButtonDebug.checked = false;
            tabButtonProfile.checked = true;
        }
    }
}
