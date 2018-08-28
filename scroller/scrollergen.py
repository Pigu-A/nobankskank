# symbol 0 is hardcoded to space ( )
DOWN_DUPS = [32,39,44,46,58,59] # ',.:;
UP_DUPS = [32,46,58] # .:

fnt = open("scroller/font_all.1bpp","rb").read()
fi = open("scroller/data.txt","rb")
dt = bytearray(fi.read().strip().upper())
fi.close()
if len(dt) == 0: raise Exception("No text data to generate")
cnt = 0
syms = [0]
csym = 1
for i in range(len(dt)):
	t = 0
	if not 32 <= dt[i] <= 96: raise IndexError("Out of range character: "+chr(dt[i]))
	elif cnt%8 == 0: pass # top/bottom
	elif cnt < 8: t = 64 if dt[i] not in DOWN_DUPS else 0
	else: t = 128 if dt[i] not in UP_DUPS else 0
	t = dt[i]-32+t
	if t not in syms:
		dt[i] = csym
		syms.append(t)
		csym += 1
	else: dt[i] = syms.index(t)
	cnt = (cnt+1)%16
open("scroller/data.bin","wb").write(dt)
fi = open("scroller/font_gen.1bpp","wb")
for i in syms: fi.write(fnt[i*8:(i+1)*8])
fi.close()
