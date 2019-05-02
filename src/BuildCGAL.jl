module BuildCGAL
using CMake



ModuleDir=pathof(BuildCGAL);
ModuleDir=splitdir(ModuleDir); #remove file name
ModuleDir=ModuleDir[1];
ModuleDir=splitdir(ModuleDir); #out of src
ModuleDir=ModuleDir[1];
#upper directory
CMakeListDir=string(ModuleDir,string("\\examples\\Advancing_front_surface_reconstruction\\")) 
#where we will build out stuff
BuildDir=string(ModuleDir,string("\\examples\\BuildDir\\")) 
cd(BuildDir)

#export as text file
str=split(string("powershell Write-Output"," $cmake | out-file -Encoding ascii 'cmakepath.txt'"))
run(`$str`)
#func def
wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)


include("SetupCGAL.jl")

end # module
