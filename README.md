# Python Cross-Architecture Compiler

This tool simplifies the process of compiling Python scripts into standalone executables for multiple CPU architectures using Docker and PyInstaller. It enables developers to build binary files for architectures different from their host machine, eliminating the need for physical hardware or complex virtualization setups.

## Overview

The script leverages Docker's multi-platform capabilities combined with QEMU emulation to cross-compile Python applications. It supports a wide range of architectures including x86_64, i386, ARM variants (armv7l, armv8l, aarch64), PowerPC (ppc64le), MIPS (mips64), IBM mainframe (s390x), and RISC-V (riscv64). This makes it particularly valuable for developers building IoT applications, embedded systems, or software that needs to run across diverse hardware platforms.

```
Usage: py-cross-compiler.sh <arch> <target> [--list] [--imports import1, import2, ...]
```

```
Architectures:
  ├─ aarch64 - Most used in SBCs and phones
  ├─ riscv64 - RISC-V 64-bit architecture
  ├─ ppc64le - Used in IBM Power Systems
  ├─ x86_64 - Most common 64-bit architecture
  ├─ mips64 - Used in routers and IoT devices
  ├─ armv7l - Mostly used in IoT devices
  ├─ armv8l - ARM 64-bit (alternate naming)
  ├─ s390x - IBM mainframe architecture
  └─ i386 - Most common 32-bit architecture
```

## How It Works

The compilation process is automated through a bash script that orchestrates Docker containers:

1. **Architecture Selection**: The user specifies the target architecture from the supported list.

2. **Environment Setup**: Docker containers with the appropriate architecture are launched using QEMU for emulation when necessary.

3. **Dependency Management**: The script handles the installation of system dependencies (gcc, zlib) and Python packages required for compilation.

4. **PyInstaller Compilation**: Inside the container, PyInstaller bundles the Python script along with all dependencies into a single executable file.

5. **Output Generation**: The compiled binary is automatically named with the target architecture suffix for easy identification.

## Key Features

- **Multi-Architecture Support**: Build for 9 different CPU architectures from a single host machine
- **Automated Dependency Handling**: Automatically installs required system and Python packages
- **Custom Import Support**: Specify additional Python packages to bundle with your application
- **Clean Build Process**: Automatically removes temporary build artifacts after compilation
- **Cross-Platform Compatibility**: Works on any system with Docker installed

This tool is ideal for developers who need to distribute Python applications across multiple platforms, test software on different architectures, or build for embedded systems and IoT devices without maintaining multiple build environments.
