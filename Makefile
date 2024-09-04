all:
	@./make.sh

.PHONY: clean
clean:
	@./make.sh --clean

rebuild: clean all