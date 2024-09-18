CXX = clang++
CC = clang
CXXFLAGS = -o2 -Wall -Wno-writable-strings
CFLAGS = -o2
LISP = sbcl

all: bankers.fasl

bankers.fasl: bankers.lisp
	$(LISP) --noinform --non-interactive --eval '(compile-file "$<")'

.PHONY: clean
clean:
	-rm -f *.bin *.fasl