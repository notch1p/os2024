CXX = clang++
CC = clang
CXXFLAGS = -o2 -Wall -Wno-writable-strings
CFLAGS = -o2 -Wall
LISP = sbcl
all: cp.bin cp.fasl

cp.bin: ConsumerProducer.c
	$(CC) $(CFLAGS) -o $@ $<

cp.fasl: ConsumerProducer.lisp
	$(LISP) --noinform --non-interactive --load $< --eval '(compile-file "$<")'

.PHONY: clean
clean:
	-rm -f *.bin *.fasl
