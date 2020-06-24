module paws.debug_service.view;

import std.conv;

import rpui.view_component;
import rpui.view;
import rpui.widget;
import rpui.widgets.tab_button.widget;
import rpui.widgets.text_input.widget;
import rpui.widgets.multiline_label.widget;
import rpui.widgets.panel.widget;

import paws.backend;

final class DebugViewComponent : ViewComponent {
    @bindWidget Widget panelTerminal;
    @bindWidget TabButton tabButtonTerminal;
    @bindWidget TextInput inputCommand;
    @bindWidget Panel panelCommands;

    this(View view, in string laytoutFileName, in string shortcutsFileName) {
        super(view, laytoutFileName, shortcutsFileName);
    }

    static DebugViewComponent create(View view) {
        return ViewComponent.createFromFileWithShortcuts!(DebugViewComponent)(view, "debug.rdl");
    }

    @shortcut("Debug.showTerminal")
    void debugLayout() {
        if (panelTerminal.isVisible && tabButtonTerminal.checked) {
            panelTerminal.isVisible = false;
            inputCommand.text = "";
            inputCommand.blur();
        }
        else {
            panelTerminal.isVisible = true;
            tabButtonTerminal.checked = true;
            inputCommand.focus();
        }
    }

    @onClickListener("buttonExecuteCommand")
    void onExecuteCommandClick() {
        // executeCommand("profile::set_snapshot_interval 30");
        executeCommand(to!string(inputCommand.text));
    }
}
