AS := 64tass
XEXFLAGS := -C -a -B --atari-xex
OFLAGS := -C -a -B -b
CC := gcc
PYTHON := python
EXE :=
LZ := utils/lzcomp${EXE}

.PHONY: all

includes := $(PYTHON) utils/incscan.py

all: pdv_nbsk.xex

${LZ}: utils/lzcomp.c
	$(CC) -O3 $< -o $@

%.asm: ;

# demo parts
%.o: dep = $(shell $(includes) $(@D)/$*.asm)
%.o: %.asm gvars.asm
	$(AS) $(OFLAGS) -o $@ $<

# right now we only use lzcomp for compressing part objects
%.lz: %.o ${LZ}
	$(LZ) $< $@

pdv_nbsk.xex: init.asm $(shell $(includes) init.asm)
	$(AS) $(XEXFLAGS) -o $@ init.asm
