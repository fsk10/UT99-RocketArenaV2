# Lists or extracts files from a UT .umod installer.
#   python -I tools/umod.py file.umod                 list
#   python -I tools/umod.py file.umod NAME OUTDIR     extract every entry whose path ends with NAME
import os, struct, sys


def ci(b, p):
    B = b[p]; p += 1; neg = B & 0x80; v = B & 0x3f
    if B & 0x40:
        sh = 6
        while True:
            B = b[p]; p += 1; v |= (B & 0x7f) << sh; sh += 7
            if not B & 0x80:
                break
    return (-v if neg else v), p


def entries(b):
    magic, dir_off, size, ver, crc = struct.unpack('<IIIII', b[-20:])
    if magic != 0x9FE3C5A3:
        sys.exit('not a umod file')
    n, p = ci(b, dir_off)
    for _ in range(n):
        l, p = ci(b, p)
        name = b[p:p + l - 1].decode('latin1'); p += l
        off, sz, flags = struct.unpack('<III', b[p:p + 12]); p += 12
        yield name, off, sz


b = open(sys.argv[1], 'rb').read()
for name, off, sz in entries(b):
    if len(sys.argv) < 4:
        print(f'{sz:>10}  {name}')
    elif name.replace('\\', '/').lower().endswith(sys.argv[2].lower()):
        out = os.path.join(sys.argv[3], os.path.basename(name.replace('\\', '/')))
        open(out, 'wb').write(b[off:off + sz])
        print(f'extracted {name} -> {out}')
