import struct, sys
def ci(b,p):
    B=b[p];p+=1;neg=B&0x80;v=B&0x3f
    if B&0x40:
        sh=6
        while True:
            B=b[p];p+=1;v|=(B&0x7f)<<sh;sh+=7
            if not B&0x80:break
    return(-v if neg else v),p
b=open(sys.argv[1],'rb').read()
tag,ver,lic,flags,nc,no,ec,eo,ic,io=struct.unpack('<IHHIIIIIII',b[:36])
names=[];p=no
for i in range(nc):
    if ver>=64:
        l,p=ci(b,p);n=b[p:p+l-1].decode('latin1');p+=l
    else:
        e=b.index(b'\0',p);n=b[p:e].decode('latin1');p=e+1
    p+=4;names.append(n)
imps=[];p=io
for i in range(ic):
    cp,p=ci(b,p);cn,p=ci(b,p);pk=struct.unpack('<i',b[p:p+4])[0];p+=4;on,p=ci(b,p)
    imps.append((names[cp],names[cn],pk,names[on]))
for i,(cp,cn,pk,on) in enumerate(imps):
    outer = imps[-pk-1][3] if pk<0 else ''
    if outer.startswith('RocketArena') or on.startswith('RocketArena'):
        print(f'{cn:10} {outer}.{on}')
