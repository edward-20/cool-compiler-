
ASSN = 2
CLASS= cs143
CLASSDIR= ../..
LIB= # link the flex library

SRC= cool.flex test.cl README personal.cl # key source files (seed of all the other files in the directory) is lex file, example cool file used as test and the README with instructions
CSRC= lextest.cc utilities.cc stringtab.cc handle_flags.cc # c source
TSRC= mycoolc # a shell script that pipes each stage of the compiler into the next
HSRC= 
CGEN= cool-lex.cc # generated c file from flex (lexer program)
HGEN=
LIBS= parser semant cgen # each of the executables for each stage of the compilation
CFIL= ${CSRC} ${CGEN} # cfiles are csource files and the generated c file
LSRC= Makefile
OBJS= ${CFIL:.cc=.o} # object files
OUTPUT= test.output # output of running lexer on the test example cool file

CPPINCLUDE= -I. -I${CLASSDIR}/include/PA${ASSN} -I${CLASSDIR}/src/PA${ASSN} # include the assignment


FFLAGS= -d -o cool-lex.cc # Flags for flex

CC=g++
CFLAGS= -g -Wall -Wno-unused -Wno-write-strings  -Wno-nonnull-compare ${CPPINCLUDE}
FLEX=flex ${FFLAGS} # command that produces output for lexer
DEPEND = ${CC} -MM ${CPPINCLUDE}


source : ${SRC} ${TSRC} ${LSRC} ${LIBS} lsource

lsource: ${LSRC}

${OUTPUT}:	lexer test.cl
	@rm -f test.output
	-./lexer test.cl >test.output 2>&1 

lexer: ${OBJS}
	echo now producing lexer
	${CC} ${CFLAGS} ${OBJS} ${LIB} -o lexer

.cc.o: # https://www.gnu.org/software/make/manual/make.html#Suffix-Rules
	echo turning c files into object files
	${CC} ${CFLAGS} -c $<

cool-lex.cc: cool.flex 
	${FLEX} cool.flex

dotest:	lexer test.cl
	./lexer test.cl

dopractice: lexer personal.cl
	./lexer personal.cl

${LIBS}:
	${CLASSDIR}/etc/link-object ${ASSN} $@

${TSRC} ${CSRC}:
	-ln -s ${CLASSDIR}/src/PA${ASSN}/$@ $@

${HSRC}:
	-ln -s ${CLASSDIR}/include/PA${ASSN}/$@ $@

clean :
	-rm -f ${OUTPUT} *.s core ${OBJS} lexer cool-lex.cc *~ parser cgen semant

clean-compile:
	@-rm -f core ${OBJS} cool-lex.cc ${LSRC}

%.d: %.cc ${SRC} ${LSRC}
	${SHELL} -ec '${DEPEND} $< | sed '\''s/\($*\.o\)[ :]*/\1 $@ : /g'\'' > $@'

-include ${CFIL:.cc=.d}


