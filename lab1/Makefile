CXXFLAGS = -o2 -Wall -Wno-writable-strings

all: basic.bin semaphore.bin

basic.bin: basic.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

semaphore.bin: semaphore.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

.PHONY: clean
clean:
	-rm -f *.bin