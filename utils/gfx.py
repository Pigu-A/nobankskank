# Converts a png image into raw a8 bitmap graphic, requires pypng
# only indexed color mode is supported right now and pixel values in the
# output gfx will correspond directly to the color index in the input gfx

import argparse, math, os, png

def png_to_xbpp(bit_width, filenames=[]):
    for fn in filenames:
        name, ext = os.path.splitext(fn)
        if ext != ".png":
            raise Exception("Don't know how to convert {}!".format(fn))
        fi = open(fn, "rb")
        width, height, data, info = png.Reader(fi).read()
        if "palette" not in info:
            raise Exception("{} is not in indexed color format!".format(fn))
        od = raw_to_xbpp(bit_width, width, height, list(data))
        fi.close()
        fo = open(name + ".{}bpp".format(bit_width), "wb")
        fo.write(od)
        fo.close()

def raw_to_xbpp(bit_width, width, height, rows):
    cols = 2**bit_width
    ppb = 8 // bit_width
    rowsize = math.ceil(width / ppb)
    # if output gfx doesn't span a full byte then fill it with index 0
    for i in range(rowsize * ppb - width):
        for j in rows: j.append(0)
    out = bytearray()
    for i in rows:
        for j in range(rowsize):
            val = 0
            for k in range(ppb):
                t = i[j * ppb + k]
                if t >= cols: t = cols-1
                val += t << (8 - (k + 1) * bit_width)
            out.append(val)
    return out
    
def png_to_lc4b(filenames=[]):
    for fn in filenames:
        name, ext = os.path.splitext(fn)
        if ext != ".png":
            raise Exception("Don't know how to convert {}!".format(fn))
        fi = open(fn, "rb")
        width, height, data, info = png.Reader(fi).read()
        if "palette" not in info:
            raise Exception("{} is not in indexed color format!".format(fn))
        dl = list(data)
        fi.close()
        dc = []
        for i in dl:
            tc = []
            for j in range(width):
                t = i[j]
                i[j] = t&15
                tc.append(t>>4)
            dc.append(tc)
        odl = raw_to_xbpp(4, width, height, dl)
        odc = raw_to_xbpp(4, width, height, dc)
        fo = open(name + "_l.4bpp", "wb")
        fo.write(odl)
        fo.close()
        fo = open(name + "_c.4bpp", "wb")
        fo.write(odc)
        fo.close()

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument('mode')
    ap.add_argument('filenames', nargs='*')
    args = ap.parse_args()

    method = {
        '1bpp': 1,
        '2bpp': 2,
        '4bpp': 4,
        'lc4b': -4,
    }.get(args.mode, None)

    if method == None:
        raise Exception("Unknown conversion method!")
    elif method == -4: png_to_lc4b(args.filenames)
    else: png_to_xbpp(method, args.filenames)
