import argparse

# tree building
class HuffTree:
	def __init__(self,a,b,c):
		self.val = a
		self.left = b
		self.right = c

class HuffLeaf:
	def __init__(self,a,b):
		self.val = a
		self.id = b
	
def buildcodes(freq):
	# build huffman code list from frequencies data
	# returns a list of sorted tuples consisting of code length, symbol and binary string
	qu = []
	for i in freq.keys(): qu.append(HuffLeaf(freq[i],i))
	while len(qu) > 1:
		qu = sorted(qu,key=lambda x: x.val)
		le = qu.pop(0)
		ri = qu.pop(0)
		qu.append(HuffTree(le.val+ri.val,le,ri))
	# walk the resulting tree to get code lengths
	t = []
	qu[0].val = 0
	while len(qu) > 0:
		i = qu.pop(0)
		v = i.val+1
		if type(i) is HuffLeaf: t.append((i.val,i.id))
		else:
			i.left.val = v
			i.right.val = v
			qu.append(i.left)
			qu.append(i.right)
	# generate canonical binary string
	v = 0
	t = sorted(t)
	for i in range(len(t)):
		t[i] += (("{:0"+str(t[i][0])+"b}").format(v),)
		if i < len(t)-1: v = (v+1)<<(t[i+1][0]-t[i][0])
	return t

def encode(s):
	freq = {}
	for i in s: freq[i] = freq.get(i,0)+1

	# tree writing
	code = buildcodes(freq)
	ls = bytearray(len(s).to_bytes(2,"little",signed=False))
	ml = code[-1][0] # since this is sorted so the last item will always have maxlen
	ls.append(ml)
	cdl = bytearray([0]*ml)
	cds = bytearray()
	cdb = {}
	for i in code:
		cdl[i[0]-1] += 1
		cds.append(i[1])
		cdb[i[1]] = i[2]
	ls += cdl+cds

	# compression
	ou = ""
	for i in s: ou = ou + cdb[i]
	while len(ou) % 8 != 0: ou = ou + "0"

	for i in range(0,len(ou),8): ls.append(int(ou[i:i+8],2))
	return ls

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('fi', metavar='in', type=argparse.FileType('rb'), help='Input file name')
	parser.add_argument('fo', metavar='out', type=argparse.FileType('wb'), help='Output file name')
	nsp = parser.parse_args()

	nf = nsp.fi.read()
	nsp.fi.close()
	ous = encode(nf)
	nsp.fo.write(ous)
	nsp.fo.close()
