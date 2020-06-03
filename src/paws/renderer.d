module paws.renderer;

import std.container.array;
import std.math;
import std.path;
import std.file;
import std.conv;
import std.stdio;

import rpui.events;
import rpui.widget;
import rpui.widgets.canvas.widget;

import gapi.vec;
import gapi.opengl;
import gapi.transform;
import gapi.texture;
import gapi.geometry;
import gapi.geometry_quad;
import gapi.shader;
import gapi.shader_uniform;
import gapi.text;

import paws.backend;

enum linesId = 0;
enum cameraId = 1;
enum textId = 2;
enum quadsId = 3;
enum sparseArrayLength = 4;

private vec2 toScreenPosition(in float windowHeight, in vec2 position, in float height) {
    return vec2(floor(position.x), floor(windowHeight - height - position.y));
}

final class Renderer : CanvasRenderer {
    private Widget widget;
    private CommandsHandler commandsHandler;

    // Data
    private Array!vec2 vec2fData;
    private Array!vec2i vec2iData;
    private Array!vec4 colorData;
    private Array!string stringsData;

    // Sparse Array
    private Array!Transform2D transform;
    private Array!mat4 modelMatrix;
    private Array!mat4 mvpMatrix;
    private Array!Buffer indicesBuffer;
    private Array!Buffer verticesBuffer;
    private Array!Buffer texCoordsBuffer;
    private Array!VAO vao;

    //
    Text gapiTextData;

    // Lines data
    private Array!vec2 linesVertices;
    private Array!uint linesIndices;

    private ShaderProgram colorShader;
    private ShaderProgram textShader;
    private ShaderProgram currentShader;

    this(CommandsHandler commandsHandler) {
        this.commandsHandler = commandsHandler;
    }

    override void onCreate(Widget widget) {
        this.widget = widget;

        createColorShader();
        createTextShader();
        initSparseArrays();
        createLineBuffer();
        createQuadsBuffer();
    }

    private void initSparseArrays() {
        for (int i = 0; i < sparseArrayLength; ++i) {
            transform.insert(Transform2D());
            modelMatrix.insert(mat4());
            mvpMatrix.insert(mat4());
            indicesBuffer.insert(Buffer());
            verticesBuffer.insert(Buffer());
            texCoordsBuffer.insert(Buffer());
            vao.insert(VAO());
        }
    }

    private void createLineBuffer() {
        linesVertices.reserve(100);
        linesIndices.reserve(100);

        linesVertices.insert(vec2(100.0f, 0.0f));
        linesVertices.insert(vec2(100.0f, 1000.0f));

        linesVertices.insert(vec2(0.0f, 100.0f));
        linesVertices.insert(vec2(1000.0f, 100.0f));

        linesIndices.insert(0);
        linesIndices.insert(1);
        linesIndices.insert(2);
        linesIndices.insert(3);

        indicesBuffer[linesId] = createIndicesBuffer(linesIndices, false);
        verticesBuffer[linesId] = createVector2fBuffer(linesVertices, false);

        vao[linesId] = createVAO();

        bindVAO(vao[linesId]);
        createVector2fVAO(verticesBuffer[linesId], inAttrPosition);
    }

    private void createQuadsBuffer() {
        indicesBuffer[quadsId] = createIndicesBuffer(quadIndices);
        verticesBuffer[quadsId] = createVector2fBuffer(quadVertices);
        texCoordsBuffer[quadsId] = createVector2fBuffer(quadTexCoords);

        vao[quadsId] = createVAO();

        bindVAO(vao[quadsId]);
        createVector2fVAO(verticesBuffer[quadsId], inAttrPosition);
        createVector2fVAO(texCoordsBuffer[quadsId], inAttrTextCoords);
    }

    override void onDestroy() {
        // TODO: Clean up
    }

    private void clearData() {
        vec2fData.clear();
        vec2iData.clear();
        colorData.clear();
        stringsData.clear();
    }

    override void onRender() {
        glClearColor(240f/255f, 240f/255f, 240f/255f, 0);
        clearData();

        const commands = commandsHandler.getRenderCommands();

        foreach (const RenderCommand command; commands) {
            handleRenderCommand(command);
        }
    }

    private void createColorShader() {
        const vertexSource = readText(buildPath("res", "shaders", "transform_vertex.glsl"));
        const vertexShader = createShader("transform vertex shader", ShaderType.vertex, vertexSource);

        const fragmentSource = readText(buildPath("res", "shaders", "color_fragment.glsl"));
        const fragmentShader = createShader("color fragment shader", ShaderType.fragment, fragmentSource);

        colorShader = createShaderProgram("color program", [vertexShader, fragmentShader]);
    }

    private void createTextShader() {
        const vertexSource = readText(buildPath("res", "shaders", "transform_vertex.glsl"));
        const vertexShader = createShader("transform vertex shader", ShaderType.vertex, vertexSource);

        const fragmentSource = readText(buildPath("res", "shaders", "text_fragment.glsl"));
        const fragmentShader = createShader("text fragment shader", ShaderType.fragment, fragmentSource);

        textShader = createShaderProgram("text program", [vertexShader, fragmentShader]);
    }

    private void handleRenderCommand(RenderCommand command) {
        switch (command.command_type) {
            case RenderCommandType.PushColor:
                colorData.insert(commandsHandler.colorData(command.data));
                break;

            case RenderCommandType.PushVec2f:
                vec2fData.insert(commandsHandler.vec2fData(command.data));
                break;

            case RenderCommandType.PushString:
                stringsData.insert(commandsHandler.stringData(command.data));
                break;

            case RenderCommandType.DrawLines:
                drawLines();
                break;

            case RenderCommandType.PushColorShader:
                bindShaderProgram(colorShader);
                currentShader = colorShader;
                break;

            case RenderCommandType.PushTextShader:
                bindShaderProgram(textShader);
                currentShader = textShader;
                break;

            case RenderCommandType.SetColorUniform:
                assert(colorData.length >= 1);
                setShaderProgramUniformVec4f(currentShader, "color", colorData[0]);
                break;

            case RenderCommandType.DrawText:
                drawText();
                break;

            default:
                debug throw new Error("Unknown command");
        }
    }

    private void handleExecCommand(ExecutionCommand command) {
        switch (command.command_type) {
            case ExecutionCommandType.PushVec2f:
                vec2fData.insert(commandsHandler.vec2fData(command.data));
                break;

            case ExecutionCommandType.UpdateCameraPosition:
                updateCameraPosition();
                break;

            default:
                writeln("Command is: ", command.command_type);
                debug throw new Error("Unknown command");
        }
    }

    override void onProgress(in ProgressEvent event) {
        commandsHandler.pushSetViewPortSize(
            cast(int) widget.width,
            cast(int) widget.height
        );
        commandsHandler.sendRequestCommands();

        const commands = commandsHandler.getExecutionCommands();

        foreach (const ExecutionCommand command; commands) {
            handleExecCommand(command);
        }

        updateLinesTransforms();
    }

    private void updateCameraPosition() {
        assert(vec2fData.length > 0);

        modelMatrix[cameraId] = mat4.translation(vec3(vec2fData[0], 0.0f));
        clearData();
    }

    private void updateLinesTransforms() {
        const screenPosition = vec2(
            widget.absolutePosition.x,
            widget.view.cameraView.viewportHeight - widget.absolutePosition.y - widget.height - 1
        );

        const screenCameraView = widget.view.cameraView;

        modelMatrix[linesId] = create2DModelMatrixPosition(screenPosition);
        mvpMatrix[linesId] = screenCameraView.mvpMatrix * modelMatrix[cameraId] * modelMatrix[linesId];
    }

    private bool updateLines() {
        if (vec2fData.length < 2) {
            return false;
        }

        linesVertices.clear();
        linesIndices.clear();

        for (int i = 0; i < vec2fData.length; ++i) {
            linesVertices.insert(vec2fData[i]);
            linesIndices.insert(i);
        }

        glBindBuffer(GL_ARRAY_BUFFER, indicesBuffer[linesId].id);
        glBufferData(GL_ARRAY_BUFFER, uint.sizeof * cast(int) linesIndices.length, &linesIndices[0], GL_STREAM_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer[linesId].id);
        glBufferData(GL_ARRAY_BUFFER, vec2.sizeof * cast(int) linesVertices.length, &linesVertices[0], GL_STREAM_DRAW);

        return true;
    }

    private void drawLines() {
        if (updateLines()) {
            setShaderProgramUniformMatrix(currentShader, "MVP", mvpMatrix[linesId]);

            bindVAO(vao[linesId]);
            bindIndices(indicesBuffer[linesId]);

            renderIndexedGeometry(cast(uint) linesIndices.length, GL_LINES);
        }

        clearData();
    }

    private void drawText() {
        auto color = vec4(0, 0, 0, 1);
        const fontScaling = widget.view.cameraView.fontScale;
        auto cameraView = widget.view.cameraView;

        if (!colorData.empty) {
            color = colorData.back;
        }

        foreach (const str; stringsData) {
            auto pos = vec2(0, 0);

            if (!vec2fData.empty) {
                pos = vec2fData.back;
                vec2fData.removeBack();
            }

            UpdateTextInput updateTextInput = {
                textSize: cast(int) ceil(12 * fontScaling),
                font: &widget.view.theme.regularFont,
                text: to!dstring(str)
            };

            const textUpdateResult = updateTextureText(&gapiTextData, updateTextInput);

            const Transform2D textTransform = {
                position: toScreenPosition(
                    cameraView.viewportHeight,
                    widget.absolutePosition + pos,
                    textUpdateResult.surfaceSize.y
                ),
                scaling: textUpdateResult.surfaceSize
            };

            const mvpMatrix = cameraView.mvpMatrix * create2DModelMatrix(textTransform);

            setShaderProgramUniformMatrix(currentShader, "MVP", mvpMatrix);
            setShaderProgramUniformVec4f(currentShader, "color", color);
            setShaderProgramUniformTexture(currentShader, "utexture", textUpdateResult.texture, 0);

            bindVAO(vao[quadsId]);
            bindIndices(indicesBuffer[quadsId]);

            renderIndexedGeometry(cast(uint) quadIndices.length, GL_TRIANGLE_STRIP);
        }

        clearData();
    }

    private void drawText(string text) {
    }
}
