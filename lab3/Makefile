CXXFLAGS = -o2 -Wall -Wno-writable-strings
CFLAGS = -o2
LISP ?= sbcl
LAKE ?= lake
all: bankers.fasl bankers.bin

bankers.fasl: bankers.lisp
	$(LISP) --noinform --non-interactive --eval '(compile-file "$<")'

bankers.bin:
	$(LAKE) --ansi build
	ln -s .lake/build/bin/lab3 ./bankers.bin

.PHONY: clean
clean:
	-rm -f *.bin *.fasl
	-lake --ansi clean