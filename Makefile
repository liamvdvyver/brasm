CC = gcc
CFLAGS = -Wall -I$(INCLUDE)
LD = ld
BUILD = out
INCLUDE = ./include/
SRC = src

default: all

all: checkdirs $(INCLUDE)/sys_headers.h brasm

$(BUILD)/brasm.o: $(SRC)/br.S
	$(CC) $(CFLAGS) -o $@ -c $^

$(INCLUDE)/sys_headers.h:
	echo "#include <sys/mman.h>" | $(CC) -E - -dM > $@

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
