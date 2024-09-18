CXX = clang++
CC = clang
CXXFLAGS = -o2 -Wall -Wno-writable-strings
CFLAGS = -o2
all: rr.bin

rr.bin: priority-rr-scheduling.c
	$(CC) $(CFLAGS) -o $@ $<


.PHONY: clean
clean:
	-rm -f *.bin