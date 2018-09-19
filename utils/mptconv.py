#!/bin/python
# coding: utf-8

"""
Convert Music ProTracker module into this demo's format.
This will strip out DOS header, make all pointers relative to the start of the file
and turn tuning tables into delta format for better compression.
The loader code (part 0) will convert this back to the original format for the player.
"""

import argparse, array

def pack_mpt(fin,fou):
	locat = array.array("H",fin.read(6))[1]
	# instrument pointers
	insptr = array.array("H",fin.read(192))
	for i in range(len(insptr)):
		if insptr[i] != 0: insptr[i] -= locat
	fou.write(insptr.tobytes())
	# tuning tables
	for i in range(4):
		tabl = array.array("B",fin.read(64))
		ot = array.array("B")
		ot.append(tabl[0])
		for j in range(1,len(tabl)):
			ot.append((tabl[j]-tabl[j-1])%256)
		fou.write(ot.tobytes())
	# order pointers
	ordptr = fin.read(8)
	ot = bytearray(8)
	for i in range(4):
		ia = (ordptr[i+4]<<8)+ordptr[i]
		oa = (ia-locat).to_bytes(2,"little",signed=False)
		ot[i] = oa[0]
		ot[i+4] = oa[1]
	fou.write(ot)
	# no more patching needed now
	therest = fin.read()
	fou.write(therest)

if __name__ == '__main__':
	ap = argparse.ArgumentParser()
	ap.add_argument("fin",type=argparse.FileType("rb"))
	ap.add_argument("fout",type=argparse.FileType("wb"))
	args = ap.parse_args()
	pack_mpt(args.fin,args.fout)
	args.fin.close()
	args.fout.close()
