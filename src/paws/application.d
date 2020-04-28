module paws.application;

import rpui.application;
import rpui.events;
import rpui.math;
import rpui.view;

import gapi.transform;
import gapi.camera;
import gapi.opengl;

debug import paws.debug_service.view;

final class MainApplication : Application {
    private View rootView;

    override void onProgress(in ProgressEvent event) {
        super.onProgress(event);
        rootView.onProgress(event);
    }

    override void onRender() {
        super.onRender();
        rootView.onRender();
    }

    override void onCreate() {
        super.onCreate();

        auto viewResources = createViewResources("light");
        viewResources.strings.setLocale("en");
        viewResources.strings.addStrings("test_view.rdl");

        rootView = new View(windowData.window, "light", cursorManager, viewResources);
        events.join(rootView.events);
        events.subscribe(rootView);

        debug DebugViewComponent.create(rootView);
    }
}
