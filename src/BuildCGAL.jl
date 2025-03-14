module BuildCGAL
using CMake

#where we will build out stuff
if Sys.islinux()
    #It should already be built
else
    BuildDir=string(splitdir(splitdir(pathof(BuildCGAL))[1])[1],string("\\examples\\BuildDir\\")) 
    try 
        cd(BuildDir)
    catch
        # Create the directory if it doesn't exist
        mkpath(BuildDir)
        cd(BuildDir)
    end
end





#func def so we can wait for users key promt
wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)

#functions we export
include("Compile_CGAL_Meshing_Functions.jl")
include("test4deps.jl")
include("SetEnviromentVarWindows.jl")
include("AdvancingFrontCGAL.jl")
include("PolygonRemeshingCGAL.jl")
include("PolygonRemeshingPatchCGAL.jl")
include("ConnectedComponentsCGAL.jl")


import CMake
if Sys.islinux()
	#You should have these built and pasted in the respective folders: see usingCGAL.md in the outer folder
else
	#export cmake dir as text file
	str=split(string("powershell Write-Output"," $cmake | out-file -Encoding ascii 'cmakepath.txt'"))
	run(`$str`)
end



end # module
