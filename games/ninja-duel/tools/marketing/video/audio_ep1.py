import numpy as np
from video import *
np.random.seed(3)
T=12.4
buf=np.zeros(int(SR*T))
buf+=beat_track(T,bpm=140,start=0.0,stop=10.5)*0.55
def at(t,snd,g=1.0): add(buf,snd*g,int(t*SR))
at(0.0,impact(),0.9)
at(0.05,whoosh(0.3),0.5); at(0.17,whoosh(0.3),0.5)
at(0.55,impact(),1.0); at(0.55,taiko(0.7,55),0.8)
at(2.35,whoosh(0.3),0.7); at(2.4,impact(0.8),0.7)
# rasengan hum
n=int(SR*1.1); t=np.arange(n)/SR
at(2.4,(np.sin(2*np.pi*220*t+3*np.sin(2*np.pi*6*t))*0.25+np.random.randn(n)*0.05)*np.minimum(1,t/0.1),0.8)
at(3.45,whoosh(0.3),0.7); at(3.5,impact(0.8),0.7); at(3.5,zap(1.0),0.6)
at(4.6,riser(3.0),0.9)
for k in range(8): at(4.6+k*0.38,zap(0.3),0.35)
at(7.75,impact(1.6),1.3); at(7.75,taiko(1.0,48),1.0)
for k,tt in enumerate([8.15,8.3]): at(tt,taiko(0.4,110),0.5)
at(10.6,taiko(1.0,55),1.0); at(10.6,impact(1.2),0.6)
write_wav('vid/ep1/audio.wav',buf)
print('ok')
