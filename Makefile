#
# Makefile for xtrs, the TRS-80 emulator.
#

OBJECTS = \
	z80.o \
	main.o \
	load_cmd.o \
	load_hex.o \
	trs_memory.o \
	trs_keyboard.o \
	error.o \
	debug.o \
	dis.o \
	trs_io.o \
	trs_cassette.o \
	trs_chars.o \
	trs_printer.o \
	trs_rom1.o \
	trs_rom1x.o \
	trs_rom3.o \
	trs_rom4p.o \
	trs_disk.o \
	trs_interrupt.o \
	trs_imp_exp.o \
	trs_hard.o \
	trs_uart.o \
	trs_stringy.o \
	common.o

X_OBJECTS = \
	trs_xinterface.o

GTK_OBJECTS = \
	keyrepeat.o \
	trs_gtkinterface.o

CR_OBJECTS = \
	compile_rom.o \
	error.o \
	load_cmd.o \
	load_hex.o

MD_OBJECTS = \
	mkdisk.o \
        common.o \
	error.o

HC_OBJECTS = \
	cmd.o \
	error.o \
	load_hex.o \
	hex2cmd.o

CD_OBJECTS = \
	cmddump.o \
	load_cmd.o

Z80CODE = export.cmd import.cmd settime.cmd xtrsmous.cmd \
	xtrs8.dct xtrshard.dct \
	fakerom.hex xtrsrom4p.hex esfrom.hex

MANPAGES = xtrs.txt mkdisk.txt cassette.txt cmddump.txt hex2cmd.txt

PDFMANPAGES = cassette.man.pdf \
	cmddump.man.pdf \
	hex2cmd.man.pdf \
	mkdisk.man.pdf \
	xtrs.man.pdf

HTMLDOCS = cpmutil.txt \
	dskspec.txt

PROGS = xtrs mkdisk hex2cmd cmddump

GXTRS = gxtrs
GLADE = '"$(SHAREDIR)/xtrs.glade"'

default: $(PROGS) docs

all: default z80code gxtrs

docs: $(MANPAGES) $(PDFMANPAGES) $(HTMLDOCS)

z80code: $(Z80CODE)

# Local customizations for make variables are done in Makefile.local:
include Makefile.local

CFLAGS += $(DEBUG) $(ENDIAN) $(DEFAULT_ROM) $(READLINE) $(DISKDIR) $(IFLAGS) \
	$(APPDEFAULTS) $(FASTMEM) -DKBWAIT -D_DARWIN_C_SOURCE

LIBS = $(XLIB) $(READLINELIBS) $(EXTRALIBS)

# For original zmac 1.3:
#ZMACFLAGS = -h -l

# For George Phillips zmac; see https://github.com/gp48k/zmac.  The -P
# flag isn't really needed, but it's here so that if someone uses zmac
# 1.3 with these flags, they'll get an error message (because zmac 1.3
# doesn't have that flag) instead of the wrong thing happening.  Ugh.
ZMACFLAGS = -P

.SUFFIXES: .z80 .cmd .dct .man .txt .hex .html

.z80.cmd:
	zmac $(ZMACFLAGS) -o $*.hex $<
	hex2cmd $*.hex > $*.cmd
	rm -f $*.hex

.z80.dct:
	zmac $(ZMACFLAGS) -o $*.hex $<
	hex2cmd $*.hex > $*.dct
	rm -f $*.hex

.z80.hex:
	zmac $(ZMACFLAGS) -o $*.hex $<

.man.txt:
	man -l $< > $*.txt
# if needed, you can try this old fashioned alternative:
#	nroff -man -c -Tascii $< | colcrt - | cat -s > $*.txt

.html.txt:
	html2text -nobs -style pretty $< >$@

%.man.pdf: %.man
	groff -man -Tpdf $< > $@
# if needed, use this workaround for https://savannah.gnu.org/bugs/?67169:
#	groff -rU0 -man -Tpdf $< > $@

xtrs: $(OBJECTS) $(X_OBJECTS)
	$(CC) $(LDFLAGS) -o xtrs $(OBJECTS) $(X_OBJECTS) $(LIBS)

gxtrs: $(OBJECTS) $(GTK_OBJECTS)
	$(CC) $(LDFLAGS) -o gxtrs -rdynamic \
		$(OBJECTS) $(GTK_OBJECTS) $(LIBS) \
		`pkg-config --libs gtk+-2.0`

compile_rom: $(CR_OBJECTS)
	$(CC) $(LDFLAGS) -o compile_rom $(CR_OBJECTS)

trs_rom1.c: compile_rom $(BUILT_IN_ROM1)
	./compile_rom 1 $(BUILT_IN_ROM1) > trs_rom1.c

trs_rom1x.c: compile_rom $(BUILT_IN_ROM1X)
	./compile_rom 1x $(BUILT_IN_ROM1X) > trs_rom1x.c

trs_rom3.c: compile_rom $(BUILT_IN_ROM3)
	./compile_rom 3 $(BUILT_IN_ROM3) > trs_rom3.c

trs_rom4p.c: compile_rom $(BUILT_IN_ROM4P)
	./compile_rom 4p $(BUILT_IN_ROM4P) > trs_rom4p.c

trs_gtkinterface.o: trs_gtkinterface.c
	$(CC) -c $(CFLAGS) -DGLADE_FILE=$(GLADE) `pkg-config --cflags gtk+-2.0` $<

keyrepeat.o: keyrepeat.c
	$(CC) -c $(CFLAGS) `pkg-config --cflags gtk+-2.0` $<

mkdisk:	$(MD_OBJECTS)
	$(CC) $(LDFLAGS) -o mkdisk $(MD_OBJECTS)

hex2cmd: $(HC_OBJECTS)
	$(CC) $(LDFLAGS) -o hex2cmd $(HC_OBJECTS)

cmddump: $(CD_OBJECTS)
	$(CC) $(LDFLAGS) -o cmddump $(CD_OBJECTS)

clean:
	rm -f $(OBJECTS) $(MD_OBJECTS) \
		$(X_OBJECTS) $(GTK_OBJECTS) \
		$(CR_OBJECTS) $(HC_OBJECTS) \
		$(CD_OBJECTS) trs_rom*.c *~ \
		$(PROGS) compile_rom gxtrs \
		$(HTMLDOCS)

veryclean: clean
	rm -f $(Z80CODE) $(MANPAGES) $(PDFMANPAGES) *.lst

link:	
	rm -f xtrs
	make xtrs

install: install-progs install-docs

install-all: install install-gxtrs

install-progs: $(PROGS) $(SRCDIR)$(CASSETTE)
	$(INSTALL) -d -m 755 $(BINDIR)
	$(INSTALL) -c -m 755 $(PROGS) $(BINDIR)
	$(INSTALL) -c -m 755 $(SRCDIR)$(CASSETTE) $(BINDIR)/cassette

install-docs: docs
	$(INSTALL) -d -m 755 $(MANDIR)
	$(INSTALL) -d -m 755 $(MANDIR)/man1
	$(INSTALL) -c -m 644 $(SRCDIR)xtrs.man $(MANDIR)/man1/xtrs.1
	$(INSTALL) -c -m 644 $(SRCDIR)cassette.man $(MANDIR)/man1/cassette.1
	$(INSTALL) -c -m 644 $(SRCDIR)mkdisk.man $(MANDIR)/man1/mkdisk.1
	$(INSTALL) -c -m 644 $(SRCDIR)cmddump.man $(MANDIR)/man1/cmddump.1
	$(INSTALL) -c -m 644 $(SRCDIR)hex2cmd.man $(MANDIR)/man1/hex2cmd.1
	$(INSTALL) -d -m 755 $(DOCDIR)
	$(INSTALL) -c -m 644 $(PDFMANPAGES) $(DOCDIR)
	$(INSTALL) -c -m 644 $(SRCDIR)cpmutil.html $(DOCDIR)
	$(INSTALL) -c -m 644 cpmutil.txt $(DOCDIR)
	$(INSTALL) -c -m 644 $(SRCDIR)dskspec.html $(DOCDIR)
	$(INSTALL) -c -m 644 dskspec.txt $(DOCDIR)

install-gxtrs: $(GXTRS)
	$(INSTALL) -d -m 755 $(BINDIR)
	$(INSTALL) -c -m 755 $(GXTRS) $(BINDIR)
	$(INSTALL) -d -m 755 $(SHAREDIR)
	$(INSTALL) -c -m 755 xtrs.glade $(SHAREDIR)

depend:
	makedepend -Y -- $(CFLAGS) -- *.c 2>&1 | \
		(egrep -v 'cannot find|not in' || true)

# DO NOT DELETE THIS LINE -- make depend depends on it.

cmddump.o: load_cmd.h
common.o: z80.h config.h trs_disk.h trs_hard.h trs_stringy.h reed.h
compile_rom.o: z80.h config.h load_cmd.h
debug.o: z80.h config.h trs.h
dis.o: z80.h config.h
error.o: z80.h config.h
hex2cmd.o: cmd.h z80.h config.h
load_cmd.o: load_cmd.h
load_hex.o: z80.h config.h
main.o: z80.h config.h trs.h trs_disk.h trs_hard.h load_cmd.h
mkdisk.o: trs_disk.h trs_hard.h trs_stringy.h z80.h config.h
trs_cassette.o: trs.h z80.h config.h
trs_chars.o: trs_iodefs.h
trs_disk.o: z80.h config.h trs.h trs_disk.h trs_hard.h crc.c
trs_gtkinterface.o: trs.h z80.h config.h trs_iodefs.h trs_disk.h trs_uart.h
trs_gtkinterface.o: trs_hard.h keyrepeat.h
trs_hard.o: trs.h z80.h config.h trs_hard.h reed.h
trs_imp_exp.o: trs_imp_exp.h z80.h config.h trs.h trs_disk.h trs_hard.h
trs_interrupt.o: z80.h config.h trs.h
trs_io.o: z80.h config.h trs.h trs_disk.h trs_hard.h trs_uart.h
trs_keyboard.o: z80.h config.h trs.h
trs_memory.o: z80.h config.h trs.h trs_disk.h trs_hard.h
trs_printer.o: z80.h config.h trs.h
trs_stringy.o: z80.h config.h trs.h trs_disk.h trs_stringy.h
trs_uart.o: trs.h z80.h config.h trs_uart.h trs_hard.h
trs_xinterface.o: trs_iodefs.h trs.h z80.h config.h trs_disk.h trs_uart.h
trs_xinterface.o: trs_hard.h trs_imp_exp.h
z80.o: z80.h config.h trs.h trs_imp_exp.h
