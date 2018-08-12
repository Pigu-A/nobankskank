import argparse, math, wave, random, hufenc

def readsamp(src,pos,size,chs): # returns a value between -0.5 and 0.5
	t = 0
	for i in range(chs):
		tt = 0
		for j in range(size):
			tt = tt + (src[pos+i*size+j] << (j * 8))
		if size == 1: # 8-bit samples are usually unsigned
			tt = tt - 128 # negative
		elif tt > 256**size/2-1: tt = tt - 256**size # negative
		t = t + tt
	return t / chs / 256.0**size

# cubic spline interpolation
def cuinterpo(s,n):
	nn = int(n)
	p0 = s[nn]
	p1 = s[nn+1]
	m0 = (s[nn+1]-s[nn-1])/2 if nn > 0 else s[nn+1]-s[nn]
	m1 = (s[nn+2]-s[nn])/2 if nn < len(s)-1 else s[nn]-s[nn-1]
	t1 = math.modf(n)[0]
	t2 = math.pow(t1,2)
	t3 = math.pow(t1,3)
	return (2*t3-3*t2+1)*p0+(t3-2*t2+t1)*m0+(-2*t3+3*t2)*p1+(t3-t2)*m1
	
def wavtoded(fd,ra,ch,wi,vol=2.0,r15=None):
	fdd = []
	fdl = []

	for i in range(0,len(fd),wi*ch): # amplify
		t = readsamp(fd, i, wi, ch)
		fdd.append(t * vol)

	ro = r15 if r15 != None else ra
	if abs(ra-ro)/ro > 0.01:
		for i in range(0,int((len(fdd))*ro/ra)): # stretch
			fdl.append(cuinterpo(fdd,i*ra/ro))
	else: fdl = fdd

	for i in range(0,len(fdl)): # convert
		fdl[i] = min(max(fdl[i]+(8.0/15.0),0),1.0)

	# TPDF dither
	last = 8
	tp = []
	freq = {}
	random.seed(3490487757541254948)
	for i in fdl:
		ev = int(i*15)
		er = i*15.0 - ev
		eo = 0.0
		if er < 0.5: eo = 2.0*er*er
		else: eo = 1.0-(2.0*(1.0-er)*(1.0-er))
		if eo > random.random(): ev = ev+1
		ew = (ev-last)%16
		tp.append(ew)
		freq[ew] = freq.get(ew,0)+1
		last = ev
	while len(tp)%32 != 0: tp.append(0)
	
	# tree writing
	code = {}
	for i in hufenc.buildcodes(freq): code[i[1]] = i[2]
	ls = bytearray(len(fdl).to_bytes(2,"little",signed=False))
	for i in range(16): ls.append(len(code.get(i,"")))

	# compression
	ou = ""
	for i in tp: ou = ou + code[i]
	while len(ou) % 8 != 0: ou = ou + "0"

	for i in range(0,len(ou),8): ls.append(int(ou[i:i+8],2))
	return ls

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('-r', type=float, help='Resample to the specified rate (Hz)')
	parser.add_argument('-v', type=float, default=2.0, help='Volume amp (default = 2.0)')
	parser.add_argument('fi', metavar='in', type=argparse.FileType('rb'), help='Input file name')
	parser.add_argument('fo', metavar='out', type=argparse.FileType('wb'), help='Output file name')
	nsp = parser.parse_args()

	fl = wave.open(nsp.fi,"rb")
	nf = fl.getnframes()
	ous = wavtoded(fl.readframes(nf), fl.getframerate(), fl.getnchannels(), fl.getsampwidth(), vol=nsp.v, r15=nsp.r)
	fl.close()
	nsp.fo.write(ous)
	nsp.fo.close()
