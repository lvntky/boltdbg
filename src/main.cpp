// src/main.cpp
#include <iostream>
// Configuration macro - set to 0 to disable GUI and use CLI
#define ENABLE_GUI 0

#if ENABLE_GUI
    // Prevent GLFW from including OpenGL headers (so glad can provide them)
    #define GLFW_INCLUDE_NONE
    #include <GLFW/glfw3.h>
    // GL loader (glad) - include after GLFW_INCLUDE_NONE so glad can provide GL
    // headers
    #if __has_include("glad/glad.h")
        #include <glad/glad.h>
        #define HAVE_GLAD 1
    #else
        #define HAVE_GLAD 0
    #endif
    // Now include ImGui and its backends (they expect glfw + GL loader to be
    // present)
    #include "backends/imgui_impl_glfw.h"
    #include "backends/imgui_impl_opengl3.h"
    #include "imgui.h"
#endif

#include <boltdbg/core/process_control.h>
#include <boltdbg/util/logger.h>

#if !ENABLE_GUI
    #include <string>

void runCLI(core::ProcessControl& processController) {
    LOG_INFO("CLI mode - Commands: step(s), continue(c), help(h), quit(q), registers(r)");

    std::string line;
    while (true) {
        fmt::print("boltdbg> ");
        std::cout.flush();

        if (!std::getline(std::cin, line)) {
            break;
        }

        // Trim whitespace
        auto start = line.find_first_not_of(" \t\n\r");
        if (start == std::string::npos)
            continue;
        auto end = line.find_last_not_of(" \t\n\r");
        line = line.substr(start, end - start + 1);

        try {
            if (line == "step" || line == "s") {
                processController.stepProcess();
                LOG_INFO("Stepped process");
            } else if (line == "continue" || line == "c") {
                processController.continueProcess();
                LOG_INFO("Continued process");
            } else if (line == "help" || line == "h") {
                LOG_INFO("Commands: step(s), continue(c), help(h), quit(q)");
            } else if (line == "quit" || line == "q") {
                LOG_INFO("Exiting");
                break;

	    } else if(line == "registers" || line == "r") {
		    LOG_INFO("Printing current register status");
		    LOG_INFO("{}", processController.regsToString());

	    } else {
                LOG_WARN("Unknown command: '{}'. Type 'help' for commands", line);
            }
        } catch (const std::exception& e) {
            LOG_ERROR("Command failed: {}", e.what());
        }
    }
}
#endif

int main(int argc, char** argv) {
    core::ProcessControl processController;
    std::list<std::string> targetProcess = {"/home/levent/Dev/boltdbg/demo/step"};
    processController.launchProcess(targetProcess);

#if ENABLE_GUI
    if (!glfwInit()) {
        LOG_ERROR("Failed to initialize GLFW");
        return 1;
    }
    // GL settings (3.3 core as example)
    const char* glsl_version = "#version 330";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    #if __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    #endif
    GLFWwindow* window = glfwCreateWindow(1280, 720, "BoltDBG", NULL, NULL);
    if (!window) {
        LOG_ERROR("Failed to create GLFW window");
        glfwTerminate();
        return 1;
    }
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);
    #if HAVE_GLAD
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        LOG_ERROR("Failed to initialize GLAD");
        return 1;
    }
    #else
    LOG_WARN("GLAD not detected at compile-time. If you experience GL "
             "symbol errors, add glad.");
    #endif
    // ImGui init
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    (void)io;
    ImGui::StyleColorsDark();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);
    LOG_INFO("Entering main loop.");
    bool show_demo = false;
    int click_count = 0;
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();
        ImGui::Begin("BoltDBG - Demo");
        ImGui::Text("Hello from BoltDBG demo!");

        ImGui::Separator();
        ImGui::Text("Process Control:");

        if (ImGui::Button("Step Process")) {
            try {
                processController.stepProcess();
                LOG_INFO("Stepped process");
            } catch (const std::exception& e) {
                LOG_ERROR("Failed to step process: {}", e.what());
            }
        }

        ImGui::SameLine();

        if (ImGui::Button("Continue Process")) {
            try {
                processController.continueProcess();
                LOG_INFO("Continued process");
            } catch (const std::exception& e) {
                LOG_ERROR("Failed to continue process: {}", e.what());
            }
        }

        ImGui::Separator();

        if (ImGui::Button("Log info with spdlog")) {
            click_count++;
            LOG_INFO("Button clicked {} times", click_count);
        }
        ImGui::Text("Click count: %d", click_count);
        ImGui::End();
        if (show_demo)
            ImGui::ShowDemoWindow(&show_demo);
        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.1f, 0.12f, 0.14f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        glfwSwapBuffers(window);
    }
    // cleanup
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();
    LOG_INFO("BoltDBG demo exiting.");
#else
    runCLI(processController);
#endif

    return 0;
}
