-- Four-character adapter contracts, independent of artistic acceptance.
return function(load,test,lib)
 local A=load("NinjaDuelAdapter");local M=load("Model");local E=load("MotionEdit");local sources=load("NinjaSources")
 local ids={"Flashstep","Mirage","GentleFist","Lion"}
 test("every core fighter exports finite ordered inert motion data and roundtrips through the adapter",function()
  for _,id in ids do
   local p=lib.presets[id];assert(p and p.metadata.characterSource==id and sources.fighters[id])
   local before=M.copy(p);local bundle=A.bundle(p,lib)
   assert(bundle.ninjaDuel.clips.Light1 and not bundle.automaticApply and not bundle.ninjaDuel.automaticApply)
   for _,clip in bundle.ninjaDuel.clips do
    local last=-1;for _,key in clip do assert(M.finite(key.at) and key.at>=last and key.at>=0 and key.at<=3.000001);last=key.at end
   end
   assert(p.clips.Light1.duration==before.clips.Light1.duration and p.name==before.name)
   local fake={IsA=function(_,name)return name=="StringValue"end,Value=A.serialize(bundle),FindFirstChild=function()return nil end}
   local imported=A.read(fake,lib);assert(imported.id==id and imported.clips.Light1 and imported.bodyLayers)
  end
 end)
 test("reference bilateral sides are accessible to every core fighter without automatic runtime assignment",function()
  for _,side in {"L","R"} do
   local id="ref_jab_"..side.."_Base";local asset=assert(lib.assets[id]);assert(lib.assets[asset.counterpart])
   for _,fighter in ids do
    local p=M.copy(lib.presets[fighter]);local export=A.bundle(p,lib,id)
    assert(export.ninjaDuel.clips[id] and export.ninjaDuel.motionMetadata[id] and not export.automaticApply)
    assert((lib.presets[fighter].motionVariants or {})[id]==nil,"export mutated the original profile")
   end
  end
 end)
 test("adapter preserves actual inherited runtime clips instead of procedural fallbacks",function()
  for child,parent in {GentleFist="Mirage",Lion="Flashstep"} do
   assert(sources.clipInheritance[child]==parent)
   for _,action in {"Air1","Air2","Grab","Throw","WallDive"} do
    local clip=assert(lib.presets[child].clips[action],child.." lacks "..action)
    assert(lib.presets[child].metadata.motionClipSources[action]==parent)
    local raw=assert(sources.clips[parent][action])
    assert(#clip.gameTimeline==#raw and clip.gameTimeline[1].at==raw[1].at)
    local timing=assert(sources.timings[child][action]);assert(math.abs(clip.duration-timing.startup-timing.active-timing.recovery)<1e-6)
   end
  end
 end)
 test("per-character edits leave other profiles and shared source assets unchanged",function()
  local p=M.copy(lib.presets.Flashstep);local source=lib.assets.ref_jab_L_Base;local duration=source.authoredClip.duration
  assert(E.variant(p,source));p.motionDNA.amplitude=.75
  local bundle=A.bundle(p,lib,source.id);assert(bundle.preset.motionDNA.amplitude==.75)
  assert(source.authoredClip.duration==duration and lib.presets.Flashstep.motionDNA.amplitude~=p.motionDNA.amplitude)
  for _,id in {"Mirage","GentleFist","Lion"} do assert(lib.presets[id].metadata.characterSource==id) end
 end)
end
