"""Extract app icons from macOS as base64 PNG for SVG embedding."""
import base64, os, subprocess as sp, tempfile
_NF = {"Iina": "IINA", "XCode": "Xcode"}
_JXA = ('ObjC.import("AppKit");var ws=$.NSWorkspace.sharedWorkspace,'
    'i=ws.iconForFile("APP");i.setSize({width:SZ,height:SZ});'
    'var r=$.NSBitmapImageRep.imageRepWithData(i.TIFFRepresentation);'
    'r.representationUsingTypeProperties($.NSBitmapImageFileTypePNG,$())'
    '.writeToFileAtomically("OUT",true);')

def _find(name):
    name=_NF.get(name,name)
    r=sp.run(["mdfind",f'kMDItemKind == "Application" && kMDItemFSName == "{name}.app"'],
             capture_output=True,text=True,timeout=5)
    p=r.stdout.strip().split("\n")[0]; return p if p and os.path.isdir(p) else None

def _icns(app):
    r=sp.run(["defaults","read",f"{app}/Contents/Info.plist","CFBundleIconFile"],
             capture_output=True,text=True,timeout=5)
    ic=r.stdout.strip()
    if not ic: return None
    if not ic.endswith(".icns"): ic+=".icns"
    p=os.path.join(app,"Contents","Resources",ic); return p if os.path.exists(p) else None

def _sips_b64(src, sz=32):
    f=tempfile.NamedTemporaryFile(suffix=".png",delete=False); tmp=f.name; f.close()
    try:
        sp.run(["sips","-s","format","png","-Z",str(sz),src,"--out",tmp],capture_output=True,timeout=10)
        with open(tmp,"rb") as f: return base64.b64encode(f.read()).decode()
    finally: os.unlink(tmp) if os.path.exists(tmp) else None

def _jxa_b64(app, sz=32):
    f=tempfile.NamedTemporaryFile(suffix=".png",delete=False); tmp=f.name; f.close()
    try:
        js=_JXA.replace("APP",app).replace("SZ",str(sz*4)).replace("OUT",tmp)
        sp.run(["osascript","-l","JavaScript","-e",js],capture_output=True,timeout=10)
        if os.path.exists(tmp) and os.path.getsize(tmp)>0:
            sp.run(["sips","-Z",str(sz),tmp,"--out",tmp],capture_output=True,timeout=5)
            with open(tmp,"rb") as f: return base64.b64encode(f.read()).decode()
    finally: os.unlink(tmp) if os.path.exists(tmp) else None

def extract_icons(names):
    icons={}
    for name in names:
        try:
            app=_find(name)
            if app:
                ic=_icns(app); b=_sips_b64(ic) if ic else _jxa_b64(app)
                if b: icons[name]=b
        except (sp.TimeoutExpired, OSError): pass
    return icons
