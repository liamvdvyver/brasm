CC = gcc
CFLAGS = -Wall -I$(INCLUDE) -g
LD = ld
BUILD = out
INCLUDE = ./include/
SRC = src

default: all

all: checkdirs $(INCLUDE)sys_headers.h brasm

$(BUILD)/brasm.o: $(SRC)/br.S
	$(CC) $(CFLAGS) -o $@ -c $^

$(BUILD)/include: $(SRC)/include.c
	$(CC) -o $@ $^

$(INCLUDE)sys_headers.h: $(BUILD)/include
	echo '#include <sys/mman.h>' | $(CC) -E - -dM > $@
	echo '#include <sys/fcntl.h>' | $(CC) -E - -dM >> $@
	sed -ni '/#define \(O\|MAP\|PROT\)_/p' $@
	sort -u $@ -o $@
	$(BUILD)/include >> $@

brasm: $(BUILD)/brasm.o
	$(LD) -o $@ $^

checkdirs: $(BUILD) $(INCLUDE)

$(BUILD):
	@mkdir -p $@

$(INCLUDE):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD)
	@rm -rf $(INCLUDE)
	@rm brasm
