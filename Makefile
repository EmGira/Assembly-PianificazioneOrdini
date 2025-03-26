sorgente = src/main.s
oggetto = obj/main.o
eseguibile = bin/pianificatore
AS = as
ASflag = --32
LD = ld
LDflag = -melf_i386

all: $(eseguibile)

$(oggetto): $(sorgente)
	@mkdir -p obj
	$(AS) $(ASflag) -o $(oggetto) $(sorgente)

$(eseguibile): $(oggetto)
	@mkdir -p bin			
	$(LD) $(LDflag) -o $(eseguibile) $(oggetto)

clean:
	rm -rf obj bin

