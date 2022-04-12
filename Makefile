ifdef windir
WINDIR=$(windir)
endif

%.42m: %.4gl 
ifdef WINDIR
	set CLASSPATH=javax.mail.jar;activation.jar && fglcomp -M -W all $*
else
	CLASSPATH=./javax.mail.jar:./activation.jar fglcomp -M -W all $*
endif


MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))

all:: $(MODS)

fgljmail.42m: javax.mail.jar activation.jar

javax.mail.jar:
	curl -L -c cookie.txt https://github.com/javaee/javamail/releases/download/JAVAMAIL-1_6_2/javax.mail.jar > $@
activation.jar:
	curl -L -c cookie.txt https://repo1.maven.org/maven2/javax/activation/activation/1.1.1/activation-1.1.1.jar >$@

run: fgljmail.42m
ifdef WINDIR
	set CLASSPATH=javax.mail.jar;activation.jar && fglrun fgljmail
else
	CLASSPATH=./javax.mail.jar:./activation.jar fglrun fgljmail
endif

clean:
	rm -f *.42?
	rm -f cookie.txt

distclean: clean
	rm -f *.jar
