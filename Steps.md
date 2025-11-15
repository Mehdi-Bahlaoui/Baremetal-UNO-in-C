## Part 1: Uploading C Code to Arduino Uno

This section focuses on using `avr-gcc`, `avr-objcopy`, and `avrdude` to compile and upload a simple C blink program to your Arduino Uno.

### 1. List All Necessary Tools

1.  **Arduino CLI**: While we're avoiding the Arduino IDE, `Arduino CLI` is an excellent way to acquire the `avr-gcc` toolchain (including `avr-gcc`, `avr-objcopy`, `avr-size`), and `avrdude` in a single, well-maintained package for Windows.
    *   **`avr-gcc`**: The GNU Compiler Collection specifically configured for AVR microcontrollers. It compiles your C source code into an object file.
    *   **`avr-libc`**: The standard C library for AVR microcontrollers. Provides common functions and header files (like `<avr/io.h>`, `<util/delay.h>`). `avr-gcc` uses this by default.
    *   **`avr-objcopy`**: A utility from GNU Binutils that converts the compiled ELF (Executable and Linkable Format) file into an Intel HEX file, which is the format `avrdude` uses for flashing.
    *   **`avr-size`**: (Optional, but useful) Reports the size of the text, data, and bss sections of an object or archive file.
2.  **`avrdude`**: A command-line utility for uploading program code (HEX files) to AVR microcontrollers. It communicates with the Arduino bootloader via the serial port.
3.  **`make`**: A build automation tool. It reads a `Makefile` to automate the compilation, linking, and uploading steps. Highly recommended for complex projects. You can get it by installing `Git for Windows`, which includes `Git Bash` where `make` is available.
4.  **Visual Studio Code (VS Code)**: Your primary editor and development environment.
    *   **C/C++ Extension**: Provides IntelliSense, debugging, and code browsing for C/C++ projects.

### 2. Step-by-Step Instructions (C Blink Program)

#### Step 2.1: Install Necessary Tools

1.  **Install `Arduino CLI`**:
    *   Download the latest `Arduino CLI` for Windows from [arduino.cc/en/software](https://arduino.cc/en/software).
    *   Extract the `arduino-cli.exe` to a convenient location (e.g., `C:\arduino-cli`).
    *   Add this directory to your system's `PATH` environment variable so `arduino-cli` can be run from any command prompt.
    *   Open a new `cmd` or `PowerShell` and run:
        ```bash
        arduino-cli config init
        arduino-cli core update-index
        arduino-cli core install arduino:avr
        ```
    *   This will download the `avr` core for Arduino, which includes `avr-gcc`, `avr-objcopy`, `avrdude`, and `avr-libc`.
    *   **Locate the Tools**: Note the installation path for these tools. You can find it by listing installed cores:
        ```bash
        arduino-cli core list
        ```
        The path will typically be something like `C:\Users\<YourUser>\AppData\Local\Arduino15\packages\arduino\tools\avr-gcc\<version>\bin\` for `avr-gcc` and `avr-objcopy`, and `C:\Users\<YourUser>\AppData\Local\Arduino15\packages\arduino\tools\avrdude\<version>\bin\` for `avrdude`.
        For simplicity, you can usually add these `bin` directories to your `PATH` or define them in your `Makefile`. We will define them in the `Makefile` for better project portability.

2.  **Install `Git for Windows` (includes `make`)**:
    *   Download and install `Git for Windows` from [git-scm.com/download/win](https://git-scm.com/download/win). During installation, ensure "Git Bash" and "Git GUI" are selected. This will provide `make` in `Git Bash`.

3.  **Install Visual Studio Code**:
    *   Download and install VS Code from [code.visualstudio.com](https://code.visualstudio.com/).
    *   Open VS Code and install the **C/C++ Extension** by Microsoft.

#### Step 2.2: Project Setup and Code

Create a new folder for your project, e.g., `arduino-c-blink`.

```
arduino-c-blink/
├── src/
│   └── main.c
├── Makefile
└── .vscode/
    ├── tasks.json
    └── c_cpp_properties.json
```

**`src/main.c` (C Blink Program)**

This program directly manipulates AVR registers to blink an LED on pin 13 (PB5 on ATmega328P).

```c
#include <avr/io.h>     // Provides definitions for AVR registers (e.g., DDRB, PORTB)
#include <util/delay.h> // Provides _delay_ms()

// Define CPU frequency for _delay_ms() macro
#ifndef F_CPU
#define F_CPU 16000000UL // 16 MHz clock speed
#endif

int main(void) {
    // Set PB5 (Digital Pin 13) as output
    // DDRB is Data Direction Register for Port B. Setting bit 5 makes PB5 an output.
    DDRB |= (1 << PB5);

    while (1) {
        // Turn LED on (set PB5 high)
        // PORTB is Port B Data Register. Setting bit 5 makes PB5 high.
        PORTB |= (1 << PB5);
        _delay_ms(500); // Wait for 500 milliseconds

        // Turn LED off (set PB5 low)
        // Clearing bit 5 makes PB5 low.
        PORTB &= ~(1 << PB5);
        _delay_ms(500); // Wait for 500 milliseconds
    }

    return 0; // Should never be reached
}
```

**`Makefile`**

This `Makefile` orchestrates the build and upload process. **Crucially, replace `<AVR_GCC_BIN_PATH>` and `<AVRDUDE_BIN_PATH>` with the actual paths you found in Step 2.1.** Also, update `UPLOAD_PORT` to your Arduino's COM port (check in Device Manager).

```makefile
# --- Configuration ---
MCU          = atmega328p
F_CPU        = 16000000UL
TARGET       = main
SRC_DIR      = src
BUILD_DIR    = build
ELF          = $(BUILD_DIR)/$(TARGET).elf
HEX          = $(BUILD_DIR)/$(TARGET).hex

# --- Tool Paths (Update these based on your Arduino CLI installation!) ---
# Example paths. Replace these placeholders with your actual paths.
# You can find these by looking inside:
# C:\Users\<YourUser>\AppData\Local\Arduino15\packages\arduino\tools\avr-gcc\<version>\bin\
# C:\Users\<YourUser>\AppData\Local\Arduino15\packages\arduino\tools\avrdude\<version>\bin\
AVR_GCC_BIN_PATH = "C:/Users/<YourUser>/AppData/Local/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino5/bin"
AVRDUDE_BIN_PATH = "C:/Users/<YourUser>/AppData/Local/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino17/bin"

CC           = $(AVR_GCC_BIN_PATH)/avr-gcc
OBJCOPY      = $(AVR_GCC_BIN_PATH)/avr-objcopy
SIZE         = $(AVR_GCC_BIN_PATH)/avr-size
AVRDUDE      = $(AVRDUDE_BIN_PATH)/avrdude

# --- Compiler Flags ---
# -mmcu: Specify microcontroller
# -DF_CPU: Define CPU frequency for _delay_ms()
# -Os: Optimize for size
# -Wall: Enable all warnings
# -Wextra: Enable extra warnings
# -std=gnu11: Use C11 standard
# -fno-split-stack: Avoid issues with stack splitting
# -ffunction-sections, -fdata-sections: Allow linker to remove unused functions/data
CFLAGS       = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os -Wall -Wextra -std=gnu11 -fno-split-stack -ffunction-sections -fdata-sections
LDFLAGS      = -mmcu=$(MCU) -Wl,--gc-sections

# --- Avrdude Upload Settings ---
UPLOAD_PROTOCOL = arduino
UPLOAD_BAUDRATE = 115200
UPLOAD_PORT     = COM3  # <--- IMPORTANT: Change this to your Arduino's COM port!

# --- Source Files ---
SRC          = $(wildcard $(SRC_DIR)/*.c)
OBJ          = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRC))

# --- Build Targets ---
.PHONY: all build upload clean size

all: build

build: $(ELF) $(HEX)
	@echo "--- Build complete ---"
	@$(SIZE) $(ELF)

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@echo "Compiling $<"
	@$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJ)
	@echo "Linking $@"
	@$(CC) $(LDFLAGS) $(OBJ) -o $@

$(HEX): $(ELF)
	@echo "Creating Intel HEX file $@"
	@$(OBJCOPY) -O ihex -R .eeprom $< $@

upload: $(HEX)
	@echo "Uploading $(HEX) to Arduino Uno on $(UPLOAD_PORT)..."
	@$(AVRDUDE) -p $(MCU) -c $(UPLOAD_PROTOCOL) -P $(UPLOAD_PORT) -b $(UPLOAD_BAUDRATE) -U flash:w:$(HEX):i
	@echo "--- Upload complete ---"

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)

```

**`.vscode/tasks.json` (VS Code Build Tasks)**

This file allows you to run `make` commands directly from VS Code.

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "build",
            "type": "shell",
            "command": "make build",
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "reveal": "always",
                "panel": "new"
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "upload",
            "type": "shell",
            "command": "make upload",
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            },
            "problemMatcher": []
        },
        {
            "label": "clean",
            "type": "shell",
            "command": "make clean",
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            },
            "problemMatcher": []
        }
    ]
}
```

**`.vscode/c_cpp_properties.json` (VS Code IntelliSense Configuration)**

This tells the C/C++ extension where to find header files for IntelliSense. **Update `<AVR_GCC_BIN_PATH>` to your `avr-gcc`'s include directory.** This is usually within the `avr/include` subdirectory of your `avr-gcc` toolchain installation. For Arduino CLI, it's typically: `C:\Users\<YourUser>\AppData\Local\Arduino15\packages\arduino\tools\avr-gcc\<version>\avr\include`.

```json
{
    "configurations": [
        {
            "name": "AVR-GCC",
            "includePath": [
                "${workspaceFolder}/**",
                // Path to avr-libc headers (e.g., avr/io.h, util/delay.h)
                // Update this path based on your Arduino CLI installation!
                "C:/Users/<YourUser>/AppData/Local/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino5/avr/include"
            ],
            "defines": [
                "F_CPU=16000000UL",
                "__AVR_ATmega328p__" // Important for some headers
            ],
            "compilerPath": "C:/Users/<YourUser>/AppData/Local/Arduino15/packages/arduino/tools/avr-gcc/7.3.0-atmel3.6.1-arduino5/bin/avr-gcc.exe",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "gcc-arm" // or gcc-x64, but gcc-arm is closer to embedded
        }
    ],
    "version": 4
}
```

#### Step 2.3: Upload the Code

1.  **Connect your Arduino Uno** to your PC via USB.
2.  **Identify the COM Port**: Open Device Manager in Windows. Under "Ports (COM & LPT)", find your Arduino Uno (it might appear as "Arduino Uno" or "USB-SERIAL CH340" etc.). Note its `COM` port number.
3.  **Update `UPLOAD_PORT` in `Makefile`**: Change `UPLOAD_PORT = COM3` to your Arduino's COM port (e.g., `COM5`).
4.  **Open the project in VS Code**.
5.  **Build**: Go to `Terminal > Run Build Task...` and select `build`. This will compile your C code and create the `.elf` and `.hex` files.
6.  **Upload**: Go to `Terminal > Run Task...` and select `upload`. This will flash the `.hex` file to your Arduino Uno.

Your Arduino Uno should now be blinking its onboard LED!

### 3. Important Notes (C Libraries)

*   **`avr-libc`**: This is the fundamental C standard library for AVR microcontrollers. Headers like `<avr/io.h>` (for register definitions) and `<util/delay.h>` (for delay functions) are part of `avr-libc`. When you use `avr-gcc`, `avr-libc` is automatically linked. You generally don't need to do anything special to "include" it beyond `include` statements in your C code.
*   **Arduino Core Libraries**: This setup *does not* use the Arduino core libraries (e.g., `digitalWrite()`, `delay()`). We are directly interacting with the microcontroller's registers for maximum control and minimal overhead, which is what "only C code" implies in this context. If you wanted to use Arduino functions without the IDE, you would need to manually compile the Arduino core source files (e.g., `wiring_digital.c`, `wiring_pulse.c`, etc.) as part of your project, which adds significant complexity and defeats the purpose of "only C code" in a bare-metal sense.
*   **VS Code IntelliSense (`c_cpp_properties.json`)**: It's crucial to correctly configure the `includePath` in `c_cpp_properties.json` so that the C/C++ extension can find the AVR-specific header files (`<avr/io.h>`, etc.). Without this, IntelliSense won't work correctly, and you'll see red squiggles for AVR-specific types and macros. The path is typically within the `avr-gcc` toolchain's `avr/include` directory.

