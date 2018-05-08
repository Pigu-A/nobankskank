#!/bin/python
# coding: utf-8

"""
Convert 64tass symbol listing into xasm symbol listing
"""

import argparse

header = "xasm 3.1.0\nLabel table:\n"
exclude = "NUM_PARTS".split(" ")

def main(f):
	symbs = set()
	fi = open(f, "r", encoding="utf-8")
	for l in fi:
		if ":=" in l: continue # no dynamic vars
		try: s, a = l.split("=")
		except ValueError: continue
		s = s.strip()
		if s in exclude: continue
		a = a.strip()
		if a[0] == "#": continue # no immediate values
		if a[0] == "$": a = int(a[1:], 16)
		elif a[0] == "%": a = int(a[1:], 2)
		else: a = int(a)
		if 0xd000 <= a < 0xd800: continue # no hw symbols, altirra already covered them
		symbs.add((s,a))
	fi.close()
	fi = open(f, "w", encoding="utf-8")
	fi.write(header)
	for i in symbs:
		fi.write("        {0[1]:04X} {0[0]}\n".format(i))

if __name__ == '__main__':
	ap = argparse.ArgumentParser()
	ap.add_argument('file')
	args = ap.parse_args()
	main(args.file)
