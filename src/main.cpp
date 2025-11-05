// src/main.cpp
#include <iostream>

// spdlog
#include <spdlog/spdlog.h>

// Prevent GLFW from including OpenGL headers (so glad can provide them)
#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

// GL loader (glad) - include after GLFW_INCLUDE_NONE so glad can provide GL headers
#if __has_include("glad/glad.h")
#include <glad/glad.h>
#define HAVE_GLAD 1
#else
#define HAVE_GLAD 0
#endif

// Now include ImGui and its backends (they expect glfw + GL loader to be present)
#include "imgui.h"
#include "backends/imgui_impl_glfw.h"
#include "backends/imgui_impl_opengl3.h"

int main(int argc, char** argv) {
    // init logger
    try {
        spdlog::set_level(spdlog::level::info);
        spdlog::info("BoltDBG demo starting (spdlog initialized).");
    } catch (const std::exception &e) {
        std::cerr << "spdlog init failed: " << e.what() << std::endl;
    }

    if (!glfwInit()) {
        spdlog::error("Failed to initialize GLFW");
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

    GLFWwindow* window = glfwCreateWindow(1280, 720, "BoltDBG - ImGui + spdlog demo", NULL, NULL);
    if (!window) {
        spdlog::error("Failed to create GLFW window");
        glfwTerminate();
        return 1;
    }
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

#if HAVE_GLAD
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        spdlog::error("Failed to initialize GLAD");
        return 1;
    }
#else
    spdlog::warn("GLAD not detected at compile-time. If you experience GL symbol errors, add glad.");
#endif

    // ImGui init
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();

    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);

    spdlog::info("Entering main loop.");

    bool show_demo = false;
    int click_count = 0;

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        ImGui::Begin("BoltDBG - Demo");
        ImGui::Text("Hello from BoltDBG demo!");
        if (ImGui::Button("Log info with spdlog")) {
            click_count++;
            spdlog::info("Button clicked {} times", click_count);
        }
        ImGui::Text("Click count: %d", click_count);
        ImGui::End();

        if (show_demo) ImGui::ShowDemoWindow(&show_demo);

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

    spdlog::info("BoltDBG demo exiting.");
    return 0;
}
