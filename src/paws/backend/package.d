module paws.backend;

import std.container.array;
import std.json;
import std.stdio;

import gapi.vec;

extern (C) {
    struct RawBuffer {
        const(byte)* data;
        size_t length;
    }

    enum SerializeFormat {
        json = 0,
        flatbuffers = 1,
    }

    enum ExecutionCommandType {
        PushVec2f = 0,
        UpdateCameraPosition = 1,
    };

    enum RenderCommandType {
        PushColor = 0,
        PushVec2f = 1,
        SetColorUniform = 2,
        PushColorShader = 3,
        DrawLines = 4,
        DrawPoints = 5,
        DrawQuads = 6,
    };

    enum RequestCommandType {
        PushVec2f = 0,
        PushVec2i = 5,
        SetViewportSize = 1,
        OnTouchStart = 2,
        OnTouchEnd = 3,
        OnTouchMove = 4,
    };

    struct Vec2f {
        float x;
        float y;
    }

    struct Vec2i {
        int x;
        int y;
    }

    struct Color {
        float r;
        float g;
        float b;
        float a;
    }

    struct CommandData {
        Vec2f vec2f;
        Vec2i vec2i;
        Color color;
    }

    struct ExecutionCommand {
        ExecutionCommandType command_type;
        CommandData data;
    }

    struct RenderCommand {
        RenderCommandType command_type;
        CommandData data;
    }

    struct RequestCommand {
        RequestCommandType command_type;
        CommandData data;
    }

    struct RenderCommands {
        const(RenderCommand)* items;
        int length;
    }

    struct ExecutionCommands {
        const(ExecutionCommand)* items;
        int length;
    }

    ExecutionCommands c_get_exec_commands();

    RenderCommands c_get_render_commands();

    void c_send_request_commands(const(RequestCommand)* data, int length);

    RawBuffer get_render_commands(SerializeFormat format);

    RawBuffer get_exec_commands(SerializeFormat format);

    void send_request_commands(SerializeFormat format, RawBuffer data);

    void init_world();

    void step();
}

CommandData createEmptyData() {
    return CommandData(
        Vec2f(0, 0),
        Vec2i(0, 0),
        Color(0, 0, 0, 0)
    );
}

CommandData createVec2fData(float x, float y) {
    return CommandData(
        Vec2f(x, y),
        Vec2i(0, 0),
        Color(0, 0, 0, 0)
    );
}

CommandData createVec2iData(int x, int y) {
    return CommandData(
        Vec2f(0, 0),
        Vec2i(x, y),
        Color(0, 0, 0, 0)
    );
}

CommandData createColorData(float r, float g, float b, float a) {
    return CommandData(
        Vec2f(0, 0),
        Vec2i(0, 0),
        Color(r, g, b, a)
    );
}

final class CommandsHandler {
    private Array!RequestCommand requestCommands;
    private Array!RenderCommand renderCommands;
    private Array!ExecutionCommand executionCommands;

    this() {
        requestCommands.reserve(10000);
        renderCommands.reserve(10000);
        executionCommands.reserve(10000);
    }

    void sendRequestCommands() {
        if (!requestCommands.empty) {
            c_send_request_commands(&requestCommands[0], cast(int) requestCommands.length);
            requestCommands.clear();
        }
    }

    void pushRequestCommand(RequestCommand command) {
        requestCommands.insert(command);
    }

    void pushSetViewPortSize(in int width, in int height) {
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.PushVec2i,
                createVec2iData(width, height)
            )
        );
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.SetViewportSize,
                createEmptyData()
            )
        );
    }

    void pushSendOnTouchStart(in float x, in float y) {
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.PushVec2f,
                createVec2fData(x, y)
            )
        );
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.OnTouchStart,
                createEmptyData()
            )
        );
    }

    void pushSendOnTouchEnd(in float x, in float y) {
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.PushVec2f,
                createVec2fData(x, y)
            )
        );
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.OnTouchEnd,
                createEmptyData()
            )
        );
    }

    void pushSendOnTouchMove(in float x, in float y) {
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.PushVec2f,
                createVec2fData(x, y)
            )
        );
        pushRequestCommand(
            RequestCommand(
                RequestCommandType.OnTouchMove,
                createEmptyData()
            )
        );
    }

    Array!RenderCommand getRenderCommands() {
        renderCommands.clear();
        const c_commands = c_get_render_commands();

        for (int i = 0; i < c_commands.length; ++i) {
            renderCommands.insert(c_commands.items[i]);
        }

        return renderCommands;
    }

    Array!ExecutionCommand getExecutionCommands() {
        executionCommands.clear();
        const c_commands = c_get_exec_commands();

        for (int i = 0; i < c_commands.length; ++i) {
            executionCommands.insert(c_commands.items[i]);
        }

        return executionCommands;
    }

    vec2 vec2fData(CommandData data) {
        return vec2(data.vec2f.x, data.vec2f.y);
    }

    vec2i vec2iData(CommandData data) {
        return vec2i(data.vec2i.x, data.vec2i.y);
    }

    vec4 colorData(CommandData data) {
        return vec4(data.color.r, data.color.g, data.color.b, data.color.a);
    }
}
