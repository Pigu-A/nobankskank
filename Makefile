AS := 64tass
XEXFLAGS := -C -a -B --atari-xex
OFLAGS := -C -a -B -b
CC := gcc
PYTHON := python3
EXE :=
LZ := utils/lzcomp${EXE}

.SUFFIXES:
.PHONY: all clean
.SECONDEXPANSION:
.PRECIOUS: %.4bpp %.2bpp %.1bpp

includes := $(PYTHON) utils/incscan.py
lstconv := $(PYTHON) utils/lstconv.py
mptconv := $(PYTHON) utils/mptconv.py
gfx := $(PYTHON) utils/gfx.py

all: pdv_nbsk.xex

clean:
	rm -f pdv_nbsk.xex
	rm -f $(LZ)
	rm -f $(shell find . -name '*.lst')
	rm -f $(shell find . -name '*.lz')

${LZ}: utils/lzcomp.c
	$(CC) -O3 $< -o $@

%.asm: ;
%.mpt: ;
%.png: ;

%.1bpp: %.png
	$(gfx) 1bpp $<
%.2bpp: %.png
	$(gfx) 2bpp $<
%.4bpp: %.png
	$(gfx) 4bpp $<

%.mpc: %.mpt
	$(mptconv) $< $@

# demo parts
%.o: dep = $(shell $(includes) $(@D)/$*.asm)
%.o: %.asm $$(dep)
	$(AS) $(OFLAGS) -l $*.lst -o $@ $<
	$(lstconv) $*.lst

# right now we only use lzcomp for compressing part objects
%.lz: %.o ${LZ}
	$(LZ) $< $@

pdv_nbsk.xex: init.asm $(shell $(includes) init.asm)
	$(AS) $(XEXFLAGS) -l init.lst -o $@ init.asm
	$(lstconv) init.lst
