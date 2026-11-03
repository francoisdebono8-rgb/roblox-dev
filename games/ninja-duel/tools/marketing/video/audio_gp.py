import numpy as np, sys
from video import *
def build(path, T, cuts, booms, riser_span, final_hit, end_t, seed):
    np.random.seed(seed)
    buf=np.zeros(int(SR*T))
    buf+=beat_track(T,bpm=150,start=0.0,stop=riser_span[0])*0.5
    buf+=beat_track(T,bpm=150,start=final_hit,stop=end_t)*0.45
    def at(t,s,g=1.0): add(buf,s*g,int(t*SR))
    at(0.0,impact(),0.9)
    for c in cuts: at(c-0.12,whoosh(0.25),0.55); at(c,taiko(0.4,80),0.6)
    for b in booms: at(b,impact(1.2),1.0); at(b,taiko(0.8,50),0.7)
    at(riser_span[0],riser(riser_span[1]-riser_span[0]),0.9)
    at(final_hit,impact(1.6),1.3); at(final_hit,taiko(1.0,45),1.0)
    at(end_t,taiko(1.0,55),1.0); at(end_t,impact(1.0),0.5)
    write_wav(path,buf)
build('vid/gp1/audio.wav',18.85,[1.2,2.3,4.8,6.3,8.0,9.8,11.6],[0.6,6.9,8.4],(11.6,14.45),14.45,17.05,4)
build('vid/gp2/audio.wav',18.05,[1.2,2.3,3.9,5.6,7.4,8.7,10.5],[0.5,3.5,9.1],(10.5,13.65),13.65,16.25,5)
print('ok')
