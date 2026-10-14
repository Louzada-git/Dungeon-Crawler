"""Original prototype sound design; stdlib only, no external recordings."""
import wave, math, random, struct
from pathlib import Path
out=Path(__file__).resolve().parents[2]/'jogo/assets/audio'
out.mkdir(parents=True,exist_ok=True)
rate=22050
for name,duration in [('step',.12),('swing',.26),('hit',.16),('hurt',.20),('loot',.24)]:
 rng=random.Random(name);smooth=0;values=[]
 for i in range(int(duration*rate)):
  t=i/rate;p=t/duration
  noise=rng.uniform(-1,1);smooth=smooth*.78+noise*.22
  if name=='step':v=(smooth*.6+math.sin(t*math.tau*85)*.20)*math.exp(-p*13)
  elif name=='swing':v=noise*.16*(math.sin(p*math.pi)**2)
  elif name=='hit':v=(smooth*.55+math.sin(t*math.tau*(140-p*65))*.30)*math.exp(-p*11)
  elif name=='hurt':v=(smooth*.25+math.sin(t*math.tau*90)*.27)*math.exp(-p*7)
  else:v=(math.sin(t*math.tau*640)+math.sin(t*math.tau*910))*.12*math.exp(-p*9)
  v*=min(1,i/40)
  values.append(struct.pack('<h',round(max(-1,min(1,v))*32767)))
 with wave.open(str(out/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(values))
print('5 sons originais gerados')
