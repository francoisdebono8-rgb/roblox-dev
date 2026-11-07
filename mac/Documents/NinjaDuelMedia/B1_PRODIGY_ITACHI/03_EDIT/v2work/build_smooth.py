# Prep only: rebuild Chidori -> Sharingan read -> fireball (T1, beats 9.15-13.0) without capture hitches.
# Exact duplicate frames (game < capture rate) are dropped, unique frames re-timed evenly.
import subprocess, json, os, sys
RUSH='../../01_RUSHES_v3/ITAKAK3_SEQ_v39t_T1.mp4'   # rush t = beat + 0.05
OFF=0.05
DEC='mpdecimate=hi=256:lo=128:frac=0.1'
ZOOM='crop=940:1670:70:165,scale=1080:1920:flags=lanczos'
def run(cmd):
    r=subprocess.run(cmd,capture_output=True,text=True)
    if r.returncode: print(r.stderr[-2000:]); sys.exit(1)
    return r
def uniq(name,b0,b1,zoom):
    vf=DEC+(','+ZOOM if zoom else '')
    run(['ffmpeg','-v','error','-y','-ss',f'{b0+OFF:.3f}','-to',f'{b1+OFF:.3f}','-i',RUSH,'-an','-vf',vf,'-fps_mode','passthrough','-c:v','libx264','-crf','10','-preset','fast',f'{name}_u.mp4'])
    n=int(run(['ffprobe','-v','error','-count_frames','-select_streams','v','-show_entries','stream=nb_read_frames','-of','csv=p=0',f'{name}_u.mp4']).stdout.strip())
    return n
def retime(name,n,frames):
    # n unique frames spread evenly over `frames` output frames at 30 fps
    dur=frames/30
    run(['ffmpeg','-v','error','-y','-i',f'{name}_u.mp4','-vf',f'setpts=N*{dur/n:.6f}/TB,fps=30,trim=end_frame={frames}','-c:v','libx264','-crf','12','-preset','medium','-pix_fmt','yuv420p',f'{name}_r.mp4'])
segA=(9.15,10.05); segB=(10.05,10.83); segC=(10.83,13.0)
nA=uniq('A',*segA,False); nB=uniq('B',*segB,True); nC=uniq('C',*segC,True)
fA=27; fB=nB; fC=135-fA-fB
print('unique frames A,B,C =',nA,nB,nC,' out frames',fA,fB,fC)
retime('A',nA,fA); retime('B',nB,fB); retime('C',nC,fC)
# audio: A normal, B stretched to slow-mo length, C fitted
gB=segB[1]-segB[0]; gC=segC[1]-segC[0]
tB=gB/(fB/30); tC=gC/(fC/30)
fc=(f"[0:a]atrim={segA[0]+OFF}:{segA[1]+OFF},asetpts=PTS-STARTPTS[a];"
    f"[0:a]atrim={segB[0]+OFF}:{segB[1]+OFF},asetpts=PTS-STARTPTS,atempo={max(0.5,tB):.4f}[b];"
    f"[0:a]atrim={segC[0]+OFF}:{segC[1]+OFF},asetpts=PTS-STARTPTS,atempo={tC:.4f}[c];"
    f"[a][b][c]concat=n=3:v=0:a=1,atrim=0:{135/30:.4f}[ao]")
run(['ffmpeg','-v','error','-y','-i',RUSH,'-filter_complex',fc,'-map','[ao]','-c:a','pcm_s16le','aud.wav'])
open('list.txt','w').write("file 'A_r.mp4'\nfile 'B_r.mp4'\nfile 'C_r.mp4'\n")
run(['ffmpeg','-v','error','-y','-f','concat','-safe','0','-i','list.txt','-i','aud.wav','-map','0:v','-map','1:a','-c:v','libx264','-crf','12','-preset','medium','-pix_fmt','yuv420p','-r','30','-c:a','aac','-b:a','192k','-shortest','../v2/E11R_chidori_read_fireball_T1_smooth.mp4'])
print('slowmo factor B =',round(1/tB,2),' C speed =',round(tC,3))
