CXX = clang++
CXXFLAGS = -o2 -Wall -Wno-writable-strings

all: basic.bin

basic.bin: basic.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<


.PHONY: clean
clean:
	-rm -f *.bin