#!/usr/bin/env python3
from pathlib import Path
import shutil
import os


platforms = ["windows", "linux", "macos"]



# copy src into a temporary directory, ignoring indev .so and .dll files
shutil.rmtree("build", ignore_errors=True)
Path("build").mkdir()
shutil.copytree("src", "build/src", ignore=shutil.ignore_patterns("*.so", "*.dll"))

# create .love file
shutil.make_archive("build/everhornet", "zip", "build/src")
os.rename("build/everhornet.zip", "build/everhornet.love")

# copy files
for platform in platforms:
    print(f"[{platform}]")
    
    Path(f"build/{platform}").mkdir()
    
    if platform == "windows":
        # copy love2d files
        shutil.copytree("bin/windows/love", "build/windows", 
            ignore=shutil.ignore_patterns("*.exe"),
            dirs_exist_ok=True)
        
        # copy libraries
        for dll in ["nuklear.dll", "nfd.dll"]:
            shutil.copy(f"bin/windows/{dll}", "build/windows")

        # copy level template
        shutil.copy("classicnet_base.p8", "build/windows")
        
        # concatenate love.exe and everhorn.love
        filenames = ["bin/windows/love/love.exe", "build/everhornet.love"]
        with open("build/windows/everhornet.exe", "wb") as of:
            for fn in filenames:
                with open(fn, "rb") as inf:
                        of.write(inf.read())
    else:
        # linux - no fancy packaging, just src and .so's
        # copy src
        shutil.copytree("build/src", f"build/{platform}", dirs_exist_ok=True)
        
        # copy .so's
        for so in ["nuklear.so", "nfd.so"]:
            shutil.copy(f"bin/{platform}/{so}", f"build/{platform}")

        # copy level template
        shutil.copy(f"classicnet_base.p8", f"build/{platform}")

# create archives    
version = input("version suffix: ")
for platform in platforms:
    arcname = f"everhornet-{version}-{platform}"
    os.rename(f"build/{platform}", f"build/{arcname}")
    
    fmt = "zip" if platform == "windows" else "gztar"
    shutil.make_archive(f"build/{arcname}", fmt, "build", arcname)

print("done")
