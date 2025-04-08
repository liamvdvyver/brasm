CC = gcc
CFLAGS = -g -Wall -I$(INCLUDE)
LD = ld
BUILD = out
INCLUDE = ./include/
SRC = .

default: all

all: checkdirs $(BUILD)/brasm

$(BUILD)/brasm.o: $(SRC)/br.S #$(INCLUDE)/sys_headers.h
	$(CC) $(CFLAGS) -o $@ -c $^

$(INCLUDE)/sys_headers.h:
	echo "#include <sys/mman.h>" | $(CC) -E - -dM > $@

$(BUILD)/brasm: $(BUILD)/brasm.o
	$(LD) -o $@ $^

checkdirs: $(BUILD) $(INCLUDE)

$(BUILD):
	@mkdir -p $@

$(INCLUDE):
	@mkdir -p $@

clean:
	@rm -rf $(BUILD)
