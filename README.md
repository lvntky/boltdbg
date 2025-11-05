# BoltDBG

⚡ A lightning-fast, modern graphical debugger for C programs built from the ground up with Dear ImGui.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)

## Overview

BoltDBG is a comprehensive debugging tool designed to streamline the development and troubleshooting of C applications. Built entirely from scratch with custom debug information parsing and powered by Dear ImGui, it delivers a responsive, modern interface with the performance and control serious developers demand.

### Why BoltDBG?

- **Built from Scratch**: Custom debug information parser with complete control over implementation
- **Lightning Fast**: Optimized rendering with Dear ImGui for smooth 60+ FPS debugging
- **Cross-Platform**: Native support for Linux, macOS, and Windows
- **Modern UI**: Clean, responsive interface with docking, customizable layouts, and themes
- **Developer-Focused**: Designed by developers, for developers

### Key Features

- **Visual Breakpoint Management**: Set, disable, and remove breakpoints with a single click
- **Real-time Variable Inspection**: Monitor variable values and memory contents as your program executes
- **Call Stack Visualization**: Navigate through function calls with a clear, hierarchical view
- **Step-by-Step Execution**: Fine-grained control with step over, step into, and step out functionality
- **Memory Viewer**: Inspect raw memory regions with hexadecimal and ASCII representations
- **Register Display**: View and track CPU register states during execution
- **Expression Evaluation**: Evaluate arbitrary C expressions in the current execution context
- **Watchpoints**: Monitor specific variables and break when they change
- **Syntax Highlighting**: Color-coded source code display for improved readability
- **Multi-threaded Debugging**: Debug applications with multiple threads simultaneously
- **Disassembly View**: See the assembly code alongside your source
- **Customizable Layouts**: Drag-and-drop panels to create your perfect workspace

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Building from Source](#building-from-source)
- [Usage](#usage)
- [Features in Detail](#features-in-detail)
- [Configuration](#configuration)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Installation

### Linux

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install boltdbg
```

#### Fedora/RHEL
```bash
sudo dnf install boltdbg
```

#### Arch Linux
```bash
yay -S boltdbg
```

### macOS

```bash
brew install boltdbg
```

### Windows

Download the installer from the [releases page](https://github.com/yourusername/boltdbg/releases) and run the setup wizard.

Alternatively, using Chocolatey:
```powershell
choco install boltdbg
```

## Quick Start

1. **Launch the debugger**:
   ```bash
   boltdbg
   ```

2. **Open your C program**:
   - Click `File > Open` or press `Ctrl+O`
   - Select your compiled executable (with debug symbols)

3. **Set a breakpoint**:
   - Click on the line number where you want to pause execution

4. **Start debugging**:
   - Click the `Run` button or press `F5`
   - Your program will execute until it hits a breakpoint

5. **Inspect and control**:
   - Use the toolbar buttons to step through code
   - View variables in the Variables panel
   - Check the call stack in the Stack panel

## Building from Source

### Prerequisites

**Required:**
- CMake 3.15+
- C++17 compatible compiler (GCC 9.0+, Clang 10.0+, MSVC 2019+)
- Git

**Platform-Specific:**
- **Linux**: X11 development libraries (`libx11-dev`, `libxrandr-dev`, `libxinerama-dev`, `libxcursor-dev`, `libxi-dev`)
- **macOS**: Xcode Command Line Tools
- **Windows**: Windows SDK

### Build Steps

```bash
# Clone the repository
git clone https://github.com/yourusername/boltdbg.git
cd boltdbg

# Initialize submodules (Dear ImGui)
git submodule update --init --recursive

# Create build directory
mkdir build && cd build

# Configure
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . -j$(nproc)

# Install (optional)
sudo cmake --install .
```

### Build Options

- `-DBOLTDBG_BUILD_TESTS=ON`: Build with unit tests
- `-DBOLTDBG_BUILD_DOCS=ON`: Generate documentation
- `-DBOLTDBG_ENABLE_ASAN=ON`: Enable AddressSanitizer for development
- `-DCMAKE_INSTALL_PREFIX=/usr/local`: Set installation directory

### Dependencies

BoltDBG uses minimal dependencies to ensure fast builds and easy maintenance:

- **Dear ImGui** (included as submodule): UI framework
- **GLFW** (included): Window and input handling
- **OpenGL 3.3+**: Graphics rendering (system)

All dependencies are either bundled or available on all target platforms.

## Usage

### Basic Debugging Session

```bash
# Debug a program with arguments
boltdbg ./myprogram arg1 arg2

# Attach to a running process
boltdbg --attach <PID>

# Load a core dump
boltdbg ./myprogram --core core.dump
```

### Command Line Options

```
Usage: boltdbg [OPTIONS] [PROGRAM] [ARGS...]

Options:
  -h, --help              Show this help message
  -v, --version           Display version information
  -a, --attach PID        Attach to running process
  -c, --core FILE         Load core dump file
  -p, --project FILE      Open project file
  -s, --symbols DIR       Additional symbol directory
  --remote HOST:PORT      Connect to remote debugging session
  --headless              Run without GUI (for automation)
  --config FILE           Use alternate configuration file
```

## Features in Detail

### Breakpoints

Set breakpoints by clicking on line numbers or using the breakpoint manager:

- **Line Breakpoints**: Pause execution at specific lines
- **Conditional Breakpoints**: Break only when conditions are met (e.g., `x > 100`)
- **Function Breakpoints**: Break when entering specific functions
- **Hardware Breakpoints**: Limited count, faster execution
- **Hit Count**: Break after N hits

### Variable Inspection

The Variables panel displays:
- Local variables in the current scope
- Global variables
- Function arguments
- Dynamically allocated memory
- Array and structure contents with expandable tree view
- Pointer following with recursive visualization
- Custom type pretty-printers

### Memory Viewer

Access the memory viewer via `View > Memory` or `Ctrl+M`:
- Hexadecimal dump with configurable bytes per row (8, 16, 32)
- ASCII representation alongside hex values
- Navigate to specific addresses
- Follow pointers with right-click menu
- Watch memory regions for changes
- Multiple memory windows with different views

### Disassembly View

View assembly code alongside source:
- Syntax-highlighted assembly
- Address and byte code display
- Jump target visualization
- Interleaved source and assembly mode
- Register value annotations

### Expression Evaluator

Evaluate C expressions in the current context:
- Support for all C operators
- Function calls (with side effects)
- Type casting
- Pointer dereferencing
- Expression history

### Customizable Layout

BoltDBG uses Dear ImGui's docking system:
- Drag and drop panels anywhere
- Create custom layouts for different workflows
- Save and load layout presets
- Multi-monitor support
- Tab groups for related panels

## Configuration

Configuration files are located at:
- **Linux**: `~/.config/boltdbg/config.json`
- **macOS**: `~/Library/Application Support/boltdbg/config.json`
- **Windows**: `%APPDATA%\boltdbg\config.json`

### Example Configuration

```json
{
  "editor": {
    "font": "JetBrains Mono",
    "font_size": 14,
    "theme": "dark",
    "show_line_numbers": true,
    "highlight_current_line": true,
    "tab_size": 4
  },
  "debugger": {
    "break_on_launch": false,
    "show_disassembly": false,
    "step_into_system_calls": false,
    "auto_load_symbols": true,
    "follow_forks": false
  },
  "ui": {
    "theme": "dark",
    "vsync": true,
    "fps_target": 60,
    "dpi_scale": 1.0,
    "layout_preset": "default"
  },
  "memory": {
    "bytes_per_row": 16,
    "show_ascii": true,
    "uppercase_hex": true
  }
}
```

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Start/Continue | `F5` |
| Step Over | `F10` |
| Step Into | `F11` |
| Step Out | `Shift+F11` |
| Toggle Breakpoint | `F9` |
| Stop Debugging | `Shift+F5` |
| Restart | `Ctrl+Shift+F5` |
| Run to Cursor | `Ctrl+F10` |
| Open File | `Ctrl+O` |
| Save Layout | `Ctrl+S` |
| Find | `Ctrl+F` |
| Go to Line | `Ctrl+G` |
| Go to Address | `Ctrl+Shift+G` |
| Toggle Disassembly | `Ctrl+D` |

## Architecture

BoltDBG is built with a modular architecture:

### Core Components

```
boltdbg/
├── src/
│   ├── core/           # Core debugger engine
│   │   ├── debugger.cpp
│   │   ├── breakpoint.cpp
│   │   ├── process.cpp
│   │   └── thread.cpp
│   ├── symbols/        # Custom symbol parser
│   │   ├── parser.cpp
│   │   ├── symbol_table.cpp
│   │   └── types.cpp
│   ├── platform/       # Platform-specific code
│   │   ├── linux/      # ptrace implementation
│   │   ├── macos/      # ptrace implementation
│   │   └── windows/    # Debug API implementation
│   ├── ui/             # Dear ImGui interface
│   │   ├── main_window.cpp
│   │   ├── code_view.cpp
│   │   ├── variables_view.cpp
│   │   ├── memory_view.cpp
│   │   ├── registers_view.cpp
│   │   └── callstack_view.cpp
│   └── main.cpp
└── external/
    ├── imgui/          # Dear ImGui submodule
    └── glfw/           # GLFW submodule
```

### Symbol System

The custom symbol system handles:
- Parsing debug information from executables
- Building symbol tables for functions and variables
- Source line mapping
- Type information storage and lookup
- Address-to-symbol resolution

### Platform Layer

Platform-specific implementations for:
- **Process control**: ptrace on Linux/macOS, Debug API on Windows
- **Memory reading/writing**: Direct process memory access
- **Register access**: Hardware register read/write
- **Signal/exception handling**: Breakpoint and fault handling
- **Thread enumeration**: Multi-threaded program support

## Troubleshooting

### Program not stopping at breakpoints

**Issue**: Breakpoints are ignored during execution.

**Solutions**:
- Ensure your program was compiled with debug symbols (`-g` flag)
- Verify the source file path matches the compiled binary
- Check that optimizations aren't removing code (`-O0` for debugging)
- Confirm debug symbols are embedded in the executable

### Cannot attach to process

**Issue**: Permission denied when attaching to a process.

**Solutions**:
- Run the debugger with elevated privileges (use `sudo` cautiously)
- On Linux, check ptrace_scope: `sudo sysctl -w kernel.yama.ptrace_scope=0`
- Ensure the target process isn't already being debugged

### Missing symbols

**Issue**: Variable names show as addresses or are unavailable.

**Solutions**:
- Install debug symbol packages for system libraries
- Add symbol search paths via `-s` option or in settings
- Rebuild your program with `-g` flag
- Verify debug symbols weren't stripped from the binary

### Performance Issues

**Issue**: Debugger feels slow or unresponsive.

**Solutions**:
- Disable VSync in settings if input feels laggy
- Reduce the number of auto-updated variables
- Reduce the number of active watchpoints
- Close unused panels to free resources
- Check GPU drivers are up to date

### Display Issues

**Issue**: UI elements appear blurry or incorrectly sized.

**Solutions**:
- Adjust DPI scaling in settings
- Try setting `dpi_scale` to match your monitor
- On Windows, disable display scaling override
- Update graphics drivers

## Contributing

We welcome contributions from the community! Here's how you can help:

### Reporting Bugs

Submit bug reports on our [issue tracker](https://github.com/yourusername/boltdbg/issues) with:
- Detailed description of the issue
- Steps to reproduce
- Expected vs actual behavior
- System information (OS, version, compiler)
- Relevant logs or screenshots
- Sample program that demonstrates the issue

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`make test`)
6. Run the formatter (`make format`)
7. Commit with clear messages (`git commit -m 'Add amazing feature'`)
8. Push to your fork (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### Development Guidelines

- Follow the C++17 standard
- Use the existing code style (run `clang-format`)
- Write unit tests for new features
- Update documentation as needed
- Keep commits focused and atomic
- Write descriptive commit messages

### Areas to Contribute

- Platform support improvements
- Symbol parsing enhancements
- UI/UX improvements
- Performance optimizations
- Documentation and examples
- Bug fixes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Dear ImGui](https://github.com/ocornut/imgui) for the user interface
- Window management via [GLFW](https://www.glfw.org/)
- Inspired by [GDB](https://www.gnu.org/software/gdb/), [LLDB](https://lldb.llvm.org/), and [RemedyBG](https://remedybg.itch.io/remedybg)

## Support

- **Documentation**: [https://boltdbg.readthedocs.io](https://boltdbg.readthedocs.io)
- **Discord**: [Join our community](https://discord.gg/yourdiscord)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/boltdbg/discussions)
- **Issues**: [GitHub Issues](https://github.com/yourusername/boltdbg/issues)

## Roadmap

- [ ] Remote debugging over network
- [ ] Time-travel debugging (record and replay)
- [ ] Plugin system for extensibility
- [ ] Integration with popular editors (VS Code, Vim, Neovim)
- [ ] Performance profiling tools
- [ ] Enhanced symbol parsing for optimized code
- [ ] Docker container debugging
- [ ] Kernel debugging support

---
