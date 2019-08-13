function PolygonRemeshingCGAL(SurfaceDir,target_edge_length)


if Sys.islinux()

	CurrentDir=pwd()

	
	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	ProgramDir=string(ModuleDir,string("/examples/BuildDirPolyMesh/"))
	cd(ProgramDir)

	outer=string("$CurrentDir","/IsotropicRemeshing.off")

	RunPolygonRemesh="./isotropic_remeshing_example $SurfaceDir $target_edge_length"
	RunPolygonRemesh=split("$RunPolygonRemesh")

	println(RunPolygonRemesh)
	try
		run(pipeline(`$RunPolygonRemesh`, "$outer"  ));
	catch
		println("Polygon remeshing failed")
	end

	cd(CurrentDir)

	OutputDirectory=string(pwd(),"/","IsotropicRemeshing.off")



elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirPolyMesh\\isotropic_remeshing_example.exe")) 
	println(Exe)

	str1="$Exe '$SurfaceDir' $target_edge_length | out-file -Encoding ascii 'IsotropicRemeshing.off'"
	RunPolygonRemesh=split("powershell $str1")
	println(RunPolygonRemesh)
	try
		run(`$RunPolygonRemesh`);
	catch
		println("Polygon remeshing failed")
	end

	OutputDirectory=string(pwd(),"\\","IsotropicRemeshing.off")

end


return OutputDirectory

end