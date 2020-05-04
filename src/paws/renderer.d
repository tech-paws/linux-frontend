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

import paws.backend;

enum linesId = 0;
enum cameraId = 1;
enum sparseArrayLength = 2;

final class Renderer : CanvasRenderer {
    private Widget widget;

    // Data
    private Array!vec2 pos2f;
    private Array!vec2 pos3f;
    private Array!vec4 color;

    // Sparse Array
    private Array!Transform2D transform;
    private Array!mat4 modelMatrix;
    private Array!mat4 mvpMatrix;
    private Array!Buffer indicesBuffer;
    private Array!Buffer verticesBuffer;
    private Array!VAO vao;

    // Lines data
    private Array!vec2 linesVertices;
    private Array!uint linesIndices;

    private ShaderProgram colorShader;
    private ShaderProgram currentShader;

    override void onCreate(Widget widget) {
        this.widget = widget;

        createColorShader();
        initSparseArrays();
        createLineBuffer();
    }

    private void initSparseArrays() {
        for (int i = 0; i < sparseArrayLength; ++i) {
            transform.insert(Transform2D());
            modelMatrix.insert(mat4());
            mvpMatrix.insert(mat4());
            indicesBuffer.insert(Buffer());
            verticesBuffer.insert(Buffer());
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

    override void onDestroy() {
        // TODO: Clean up
    }

    private void clearData() {
        pos2f.clear();
        pos3f.clear();
        color.clear();
    }

    override void onRender() {
        glClearColor(240f/255f, 240f/255f, 240f/255f, 0);
        clearData();

        const commands = getRenderCommands();

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

    private void handleRenderCommand(RenderCommand command) {
        switch (command.type) {
            case RenderCommandType.pushColor:
                color.insert(command.value.vec4f);
                break;

            case RenderCommandType.pushPos2f:
                pos2f.insert(command.value.vec2f);
                break;

            case RenderCommandType.drawLines:
                drawLines();
                break;

            case RenderCommandType.pushColorShader:
                bindShaderProgram(colorShader);
                break;

            case RenderCommandType.setColorUniform:
                assert(color.length >= 1);
                currentShader = colorShader;
                setShaderProgramUniformVec4f(colorShader, "color", color[0]);
                break;

            default:
                debug throw new Error("Unknown command");
        }
    }

    private void handleExecCommand(ExecCommand command) {
        switch (command.type) {
            case ExecCommandType.pushPos2f:
                pos2f.insert(command.value.vec2f);
                break;

            case ExecCommandType.updateCameraPosition:
                updateCameraPosition();
                break;

            default:
                debug throw new Error("Unknown command");
        }
    }

    override void onProgress(in ProgressEvent event) {
        const commands = getExecCommands();

        foreach (const ExecCommand command; commands) {
            handleExecCommand(command);
        }

        updateLinesTransforms();

        set_view_port_size(
            cast(int) widget.width,
            cast(int) widget.height
        );
    }

    private void updateCameraPosition() {
        assert(pos2f.length > 0);

        modelMatrix[cameraId] = mat4.translation(vec3(pos2f[0], 0.0f));
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
        if (pos2f.length < 2) {
            return false;
        }

        linesVertices.clear();
        linesIndices.clear();

        for (int i = 0; i < pos2f.length; ++i) {
            linesVertices.insert(pos2f[i]);
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
            clearData();
        }
    }
}
