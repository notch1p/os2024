CXX = clang++
CC = clang
LISP = sbcl
LAKE = lake
ifeq ($(detected_OS),Linux)
	CC  := gcc
	CXX := g++
endif

all:
	@./make.sh

.PHONY: clean
clean:
	@./make.sh --clean

rebuild: clean all