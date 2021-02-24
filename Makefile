#BINARY := cm3.elf
#MACHINE := lm3s6965evb

BINARY := kernel.elf
MACHINE := musca-b1 #mps2-an505
DEVICE := ARMCM33
CPU := cortex-m33
MEMORY_SIZE := 16m

# Variable with ?= assignement can be redefined when the makefile is called:
# make QEMU_PATH=qemu-system-arm will update the variable of the Makefile
CMSIS ?= ./CMSIS_5
# Use QEMU_PATH = qemu-system-arm if QEMU was installed through the apt command.
QEMU_PATH ?= qemu-system-arm
TOOLCHAIN ?= ./gcc-arm-none-eabi-9-2019-q4-major/bin

QEMU_COMMAND := $(QEMU_PATH) \
	-machine $(MACHINE) \
	-cpu $(CPU) \
	-m $(MEMORY_SIZE) \
	-nographic \
	-semihosting \
	-device loader,file=$(BINARY) \
	-machine accel=tcg

BINARY_OBJDUMP := objdump_$(BINARY)

CROSS_COMPILE = arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
GDB = $(CROSS_COMPILE)gdb
OBJ = $(CROSS_COMPILE)objdump

LINKER_SCRIPT = gcc_arm.ld

SRC_ASM = $(CMSIS)/Device/ARM/$(DEVICE)/Source/GCC/startup_$(DEVICE).S

SRC_C = $(CMSIS)/Device/ARM/$(DEVICE)/Source/system_$(DEVICE).c

#SRC_C += main.c
SRC_C += start.c

INCLUDE_FLAGS = -I$(CMSIS)/Device/ARM/$(DEVICE)/Include \
	-I$(CMSIS)/CMSIS/Core/Include \
	-I. \
	$(INCLUDE_FLAGS_APP)

CFLAGS = -mcpu=$(CPU) \
         -specs=nano.specs \
         -specs=nosys.specs \
         -specs=rdimon.specs \
         -Wall \
	       -g3 \
	       $(INCLUDE_FLAGS) \
	       -mthumb \
	       -nostartfiles

all: $(BINARY)

boot.o: $(SRC_ASM)
	$(CC) $(CFLAGS) -c $^ -o $@

$(BINARY): $(SRC_C) boot.o
	$(CC) $^ $(CFLAGS) -T $(LINKER_SCRIPT) -o $@
	$(OBJ) -D $@ > $(BINARY_OBJDUMP)


# Ctrl-A, then X to quit QEMU
run: $(BINARY)
	-$(QEMU_COMMAND) -d int,cpu_reset
	echo $? " has exited"

gdbserver: $(BINARY)
	$(QEMU_COMMAND) -S -s -d int,cpu_reset

help:
	$(QEMU_PATH) --machine help

gdb: $(BINARY)
	$(GDB) $(BINARY) -ex "target remote:1234"

clean:
	rm -f $(BINARY_OBJDUMP) *.o *.elf
