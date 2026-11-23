import sys, numpy as np
from PIL import Image
def matte(ib,iw,pb,pw,out):
    Ib,Iw,Pb,Pw=[np.asarray(Image.open(p).convert('RGB')).astype(np.float32) for p in (ib,iw,pb,pw)]
    d=(Pw-Pb).mean(2); d=np.maximum(d,1)
    a=1-((Iw-Ib).mean(2))/d
    a=np.clip((a-0.04)/0.92,0,1)
    a[(Pw-Pb).mean(2)<20]=0
    F=(Ib-(1-a[...,None])*Pb)/np.maximum(a[...,None],1e-3)
    F=np.clip(F,0,255)
    rgba=np.dstack([F,a*255]).astype(np.uint8)
    im=Image.fromarray(rgba,'RGBA')
    bb=im.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox()
    im.save(out); print(out,bb)
if __name__=='__main__': matte(*sys.argv[1:6])
