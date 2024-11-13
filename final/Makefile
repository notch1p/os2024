all : final.exe

DUNE ?= dune

OPAMSWITCH = $(shell opam switch show)

final.exe:
	eval $$(opam env --switch=$(OPAMSWITCH)) && $(DUNE) build --release

.PHONY: clean
clean:
	eval $$(opam env --switch=$(OPAMSWITCH)) && $(DUNE) clean