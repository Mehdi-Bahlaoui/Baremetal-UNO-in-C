# --- Configuration ---
MCU          = atmega328p
F_CPU        = 16000000UL
TARGET       = main
SRC_DIR      = src
BUILD_DIR    = build
ELF          = $(BUILD_DIR)/$(TARGET).elf
HEX          = $(BUILD_DIR)/$(TARGET).hex

# --- Tool Paths 

AVR_GCC_BIN_PATH = "C:\Users\midou\AppData\Local\Arduino15\packages\arduino\tools\avr-gcc\7.3.0-atmel3.6.1-arduino7\bin"
AVRDUDE_BIN_PATH = "C:\Users\midou\AppData\Local\Arduino15\packages\arduino\tools\avrdude\6.3.0-arduino17\bin"
AVRDUDE_CONF     = "C:\Users\midou\AppData\Local\Arduino15\packages\arduino\tools\avrdude\6.3.0-arduino17\etc\avrdude.conf"

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

build: $(HEX)
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
	@$(AVRDUDE) -C $(AVRDUDE_CONF) -p $(MCU) -c $(UPLOAD_PROTOCOL) -P $(UPLOAD_PORT) -b $(UPLOAD_BAUDRATE) -U flash:w:$(HEX):i
	@echo "--- Upload complete ---"

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)