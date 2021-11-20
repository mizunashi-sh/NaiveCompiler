all: build remove

build:   compiler.l compiler.y
	lex compiler.l
	bison -d compiler.y
	clang `pkg-config --cflags gtk+-2.0` -g -o compiler lex.yy.c compiler.tab.c -lm `pkg-config --libs gtk+-2.0`

remove:  
	rm lex.yy.c compiler.tab.c compiler.tab.h

clean:
	rm compiler
	rm -rf compiler.dSYM