module paws.application;

import rpui.application;
import rpui.events;
import rpui.math;
import rpui.view;

import gapi.transform;
import gapi.camera;
import gapi.opengl;

import paws.backend;
debug import paws.debug_service.view;
import paws.scheme_editor.view;

final class MainApplication : Application {
    private View rootView;

    override void onProgress(in ProgressEvent event) {
        super.onProgress(event);
        rootView.onProgress(event);
    }

    override void onFrameStart() {
        super.onFrameStart();
        frame_start();
    }

    override void onFrameEnd() {
        super.onFrameEnd();
        frame_end();
    }

    override void onRender() {
        super.onRender();
        rootView.onRender();
        step();
    }

    override void onCreate() {
        super.onCreate();

        init_world();

        auto viewResources = createViewResources("light");
        viewResources.strings.setLocale("en");
        viewResources.strings.addStrings("test_view.rdl");

        rootView = new View(windowData.window, "light", cursorManager, viewResources);
        events.join(rootView.events);
        events.subscribe(rootView);

        debug DebugViewComponent.create(rootView);
        SchemeEditorViewComponent.create(rootView);
    }
}
