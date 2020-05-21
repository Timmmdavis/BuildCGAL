function PolygonRemeshingPatchCGAL(SurfaceDir,TriNumbersTxtDir,target_edge_length)

#SurfaceDir - directory of the .Off file
#TriNumbersTxtDir - directory of a txt file that is a list of triangle numbers (the patch of the mesh) that will be remeshed (starting from index 1). /n seperates each val (col of vals)
#target_edge_length - desired edge length of the triangles in the patch 

#= Simple way of exporting the tri nos we want: (flag is just a logical on which midpoints we like...)
using DelimitedFiles
TriNos=findall(flag)
Filename="TriNos.txt"
open(Filename, "w") do io
   writedlm(io, vec(TriNos))
end
TriNumbersTxtDir=string(pwd(),raw"\\",Filename)
=#

if Sys.islinux()

	CurrentDir=pwd()

	
	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	ProgramDir=string(ModuleDir,string("/examples/BuildDirPolyMesh/"))
	cd(ProgramDir)

	outer=string("$CurrentDir","/IsotropicRemeshingPatch.off")

	RunPolygonRemesh="./isotropic_remeshing_of_patch_example $SurfaceDir $target_edge_length $TriNumbersTxtDir"
	RunPolygonRemesh=split("$RunPolygonRemesh")

	println(RunPolygonRemesh)
	try
		run(pipeline(`$RunPolygonRemesh`, "$outer"  ));
	catch
		println("Polygon remeshing failed")
	end

	cd(CurrentDir)

	OutputDirectory=string(pwd(),"/","IsotropicRemeshingPatch.off")



elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirPolyMesh\\isotropic_remeshing_of_patch_example.exe")) 
	println(Exe)

	str1="$Exe '$SurfaceDir' $target_edge_length $TriNumbersTxtDir | out-file -Encoding ascii 'IsotropicRemeshingPatch.off'"
	RunPolygonRemesh=split("powershell $str1")
	println(RunPolygonRemesh)
	try
		run(`$RunPolygonRemesh`);
	catch
		println("Polygon remeshing failed")
	end

	OutputDirectory=string(pwd(),"\\","IsotropicRemeshingPatch.off")

end


return OutputDirectory

end