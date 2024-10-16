CXX = clang++
CC = clang
CXXFLAGS = -o2 -Wall -Wno-writable-strings
CFLAGS = -o2 -Wall
all: cp.bin 

cp.bin: ConsumerProducer.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	-rm -f *.bin