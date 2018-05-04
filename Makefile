AS := 64tass
XEXFLAGS := -C -a -B --atari-xex
OFLAGS := -C -a -B -b
CC := gcc
PYTHON := python
EXE :=
LZ := utils/lzcomp${EXE}

.PHONY: all clean

includes := $(PYTHON) utils/incscan.py
parts := 0_loader_music.lz 1_botb_logo.lz

all: pdv_nbsk.xex

clean:
	rm -f pdv_nbsk.xex
	rm -f $(LZ)
	rm -f $(shell find . -name '*.lz')

${LZ}: utils/lzcomp.c
	$(CC) -O3 $< -o $@

%.asm: ;

# demo parts
%.o: dep = $(shell $(includes) $(@D)/$*.asm)
%.o: %.asm $(dep)
	$(AS) $(OFLAGS) -o $@ $<

# right now we only use lzcomp for compressing part objects
%.lz: %.o ${LZ}
	$(LZ) $< $@

pdv_nbsk.xex: init.asm $(shell $(includes) init.asm) $(parts)
	$(AS) $(XEXFLAGS) -o $@ init.asm
