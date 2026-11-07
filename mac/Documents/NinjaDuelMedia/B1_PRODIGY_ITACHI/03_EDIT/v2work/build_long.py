# Prep only (CapCut does the montage): long shots from the two takes, capture duplicates removed,
# unique frames re-timed evenly, optional slow-mo and light zoom. Output 30 fps 1080x1920 + game audio.
import subprocess, sys, json, os
RUSH={'T1':'../../01_RUSHES_v3/ITAKAK3_SEQ_v39t_T1.mp4','T2':'../../01_RUSHES_v3/ITAKAK3_SEQ_v39t_T2.mp4','RAW':'../../00_PROOF/RAW_ITAKAK3_2026-11-05_16-27-59.mov'}
OFFS={'T1':0.05,'T2':0.05,'RAW':0.0}
BASE={'RAW':'crop=697:1239:1027:395,scale=1080:1920:flags=lanczos,'}
OFF=0.05                      # rush time = beat + 0.05
DEC='mpdecimate=hi=64:lo=32:frac=0.02'
# segments: (take, beat0, beat1, speed, zoom, cx, cy)   cx,cy in 1080x1920 rush pixels
SHOTS={
 'S1_long':    [('RAW',36.90,38.10,1.0,1.0,540,960),('T2',0.07,0.95,0.5,1.35,540,1050),('T2',0.95,2.40,1.0,1.35,540,1050)],
 'S1_throw':   [('T2',0.07,0.70,0.5,1.35,540,1050),('T2',0.70,2.40,1.0,1.35,540,1050)],
 'S2_cut':     [('T1',2.40,3.30,1.0,1.15,540,1000),('T2',3.30,4.40,1.0,1.0,540,960)],
 'S3_dodge':   [('T1',4.40,5.60,1.0,1.2,540,1000)],
 'S4_press':   [('T2',5.60,7.60,1.0,1.0,540,960)],
 'S5_fang':    [('T1',7.60,9.10,1.0,1.0,540,960)],
 'S6_read':    [('T1',9.10,10.00,1.0,1.0,540,960),('T1',10.00,10.85,0.55,1.25,540,1000),('T1',10.85,11.30,1.0,1.25,540,1000)],
 'S7_fireball':[('T1',11.30,12.10,1.0,1.2,540,980),('T1',12.10,12.50,0.5,1.2,540,980),('T1',12.50,13.50,1.0,1.2,540,980)],
 'S8_itachi':  [('T2',13.50,14.90,1.0,1.0,540,960)],
}
def run(cmd):
    r=subprocess.run(cmd,capture_output=True,text=True)
    if r.returncode: print(r.stderr[-1500:]); sys.exit(1)
    return r.stdout
def zoomf(z,cx,cy):
    if z<=1.0: return ''
    w=int(round(1080/z/2))*2; h=int(round(1920/z/2))*2
    x=min(max(0,int(cx-w/2)),1080-w); y=min(max(0,int(cy-h/2)),1920-h)
    return f',crop={w}:{h}:{x}:{y},scale=1080:1920:flags=lanczos'
def seg(i,take,b0,b1,sp,z,cx,cy):
    u=f'tmp/u{i}.mp4'; r=f'tmp/r{i}.mp4'; a=f'tmp/a{i}.wav'
    mf=f'tmp/m{i}.txt'
    run(['ffmpeg','-v','error','-y','-ss',f'{b0+OFFS[take]:.3f}','-to',f'{b1+OFFS[take]:.3f}','-i',RUSH[take],'-an','-vf',BASE.get(take,'')+f'signalstats,metadata=print:key=lavfi.signalstats.YDIF:file={mf}','-f','null','-'])
    yd=[float(l.split('=')[1]) for l in open(mf) if 'YDIF=' in l]
    drop=[k for k,v in enumerate(yd) if k>0 and v<0.2]
    sel=("select='not(" + '+'.join(f'eq(n,{k})' for k in drop) + ")',") if drop else ''
    run(['ffmpeg','-v','error','-y','-ss',f'{b0+OFFS[take]:.3f}','-to',f'{b1+OFFS[take]:.3f}','-i',RUSH[take],'-an','-vf',BASE.get(take,'')+sel+'null'+zoomf(z,cx,cy),'-vsync','passthrough','-c:v','libx264','-crf','10','-preset','veryfast',u])
    n=int(run(['ffprobe','-v','error','-count_frames','-select_streams','v','-show_entries','stream=nb_read_frames','-of','csv=p=0',u]).strip())
    frames=n if sp<1 else round((b1-b0)/sp*30); dur=frames/30
    sp=(b1-b0)/dur if sp<1 else sp   # slow-mo: every unique game frame shown once
    run(['ffmpeg','-v','error','-y','-i',u,'-vf',f'setpts=N*{dur/n:.6f}/TB,fps=30,trim=end_frame={frames},setpts=PTS-STARTPTS','-c:v','libx264','-crf','12','-preset','medium','-pix_fmt','yuv420p',r])
    run(['ffmpeg','-v','error','-y','-ss',f'{b0+OFFS[take]:.3f}','-to',f'{b1+OFFS[take]:.3f}','-i',RUSH[take],'-vn','-af',f'atempo={sp},apad,atrim=0:{dur:.4f}','-ar','48000','-ac','2',a])
    return r,a,frames,n
log={}
for name in (sys.argv[1:] or SHOTS):
    parts=[]; meta=[]
    for i,s in enumerate(SHOTS[name]):
        r,a,f,n=seg(f'{name}_{i}',*s); parts.append((r,a)); meta.append({'seg':s,'frames':f,'unique':n})
    with open('tmp/l.txt','w') as fh:
        for r,a in parts: fh.write(f"file '{os.path.basename(r)}'\n")
    with open('tmp/la.txt','w') as fh:
        for r,a in parts: fh.write(f"file '{os.path.basename(a)}'\n")
    run(['ffmpeg','-v','error','-y','-f','concat','-safe','0','-i','tmp/l.txt','-f','concat','-safe','0','-i','tmp/la.txt','-map','0:v','-map','1:a','-c:v','copy','-c:a','aac','-b:a','192k','-shortest',f'../v2/{name}.mp4'])
    log[name]=meta; print(name, [(m['frames'],m['unique']) for m in meta])
old=json.load(open('shots_log.json')) if os.path.exists('shots_log.json') else {}
old.update(log); json.dump(old,open('shots_log.json','w'),indent=1)
