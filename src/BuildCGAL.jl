module BuildCGAL
using CMake

ModuleDir=pathof(BuildCGAL);
ModuleDir=splitdir(ModuleDir); #remove file name
ModuleDir=ModuleDir[1];
ModuleDir=splitdir(ModuleDir); #out of src
ModuleDir=ModuleDir[1];
#where we will build out stuff
BuildDir=string(ModuleDir,string("\\examples\\BuildDir\\")) 
cd(BuildDir)




#func def so we can wait for users key promt
wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)

#functions we export
include("SetupCGAL.jl")
include("test4deps.jl")
include("SetEnviromentVarWindows.jl")

import CMake
#export cmake dir as text file
str=split(string("powershell Write-Output"," $cmake | out-file -Encoding ascii 'cmakepath.txt'"))
run(`$str`)


end # module
