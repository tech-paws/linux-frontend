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

    RawBuffer get_render_commands();

    void init_world();

    void step();
}

string rawBufferToString(RawBuffer buffer) {
    return (cast(immutable(char)*)buffer.data)[0..buffer.length];
}

enum RenderCommandType {
    pushColor,
    pushPos2f,
    drawLines,
    pushColorShader,
    setColorUniform,
}

struct RenderCommand {
    RenderCommandType type;
    RenderCommandValue value;
}

union RenderCommandValue {
    vec2 vec2f;
    vec3 vec3f;
    vec4 vec4f;
}

Array!RenderCommand getRenderCommands() {
    Array!RenderCommand commands;

    const buffer = get_render_commands();
    const jsonString = rawBufferToString(buffer);

    auto json = parseJSON(jsonString);

    debug assert(json.type() == JSONType.array);

    foreach (JSONValue value; json.array()) {
        const command = parseRenderCommand(value);
        commands.insert(command);
    }

    return commands;
}

private RenderCommand parseRenderCommand(JSONValue json) {
    RenderCommand renderCommand;

    renderCommand.type = parseRenderCommandType(json);

    switch (renderCommand.type) {
        case RenderCommandType.pushColor:
            const obj = json.object()["PushColor"].object();
            renderCommand.value.vec4f = vec4(
                obj["r"].floating(),
                obj["g"].floating(),
                obj["b"].floating(),
                obj["a"].floating()
            );
            break;

        case RenderCommandType.pushPos2f:
            const obj = json.object()["PushPos2f"].object();
            renderCommand.value.vec2f = vec2(
                obj["x"].floating(),
                obj["y"].floating(),
            );
            break;

        case RenderCommandType.drawLines:
            // No data
            break;

        case RenderCommandType.pushColorShader:
            // No data
            break;

        case RenderCommandType.setColorUniform:
            // No data
            break;

        default:
            throw new Error("Unknown command type");
    }

    return renderCommand;
}

private RenderCommandType parseRenderCommandType(JSONValue json) {
    string type;

    switch (json.type()) {
        case JSONType.string:
            type = json.str();
            break;

        case JSONType.object:
            foreach (key, value; json.object()) {
                type = key;
                break;
            }

            break;

        default:
            throw new Error("Unknown command");
    }

    switch (type) {
        case "PushColor":
            return RenderCommandType.pushColor;

        case "PushPos2f":
            return RenderCommandType.pushPos2f;

        case "DrawLines":
            return RenderCommandType.drawLines;

        case "PushColorShader":
            return RenderCommandType.pushColorShader;

        case "SetColorUniform":
            return RenderCommandType.setColorUniform;

        default:
            throw new Error("Unknown command");
    }
}
