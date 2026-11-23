import subprocess, numpy as np, sys, json
src=sys.argv[1]; out=sys.argv[2]
W,H=384,189
p=subprocess.Popen(['ffmpeg','-v','error','-i',src,'-vf',f'scale={W}:{H}','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
res=[]
while True:
    b=p.stdout.read(W*H*3)
    if len(b)<W*H*3: break
    f=np.frombuffer(b,np.uint8).reshape(H,W,3).astype(np.int16)
    r,g,bl=f[...,0],f[...,1],f[...,2]
    y0,y1=int(H*0.14),int(H*0.88)
    reg=(slice(y0,y1),slice(0,W))
    orange=(r>200)&(g>90)&(g<190)&(bl<90)
    blue=(bl>120)&(bl-r>50)&(bl-g>30)&(r<110)
    def cen(m):
        m=m[reg]; ys,xs=np.nonzero(m)
        if len(xs)<6: return None
        return float(np.median(xs))/W, float(np.median(ys)+y0)/H, int(len(xs))
    res.append([cen(orange),cen(blue)])
json.dump(res,open(out,'w'))
print(len(res))
