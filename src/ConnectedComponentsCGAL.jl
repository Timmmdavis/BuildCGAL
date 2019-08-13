function ConnectedComponentsCGAL(SurfaceDir)


if Sys.islinux()
	
	CurrentDir=pwd()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	ProgramDir=string(ModuleDir,string("/examples/BuildDirPolyMesh/"))
	cd(ProgramDir)

	outer=string("$CurrentDir","/ConnectedComponents.txt")

	RunConnectedComponents="./connected_components_example $SurfaceDir"
	RunConnectedComponents=split("$RunConnectedComponents")

	println(RunConnectedComponents)
	try
		run(pipeline(`$RunConnectedComponents`, "$outer"  ));
	catch
		println("Connected component finding failed")
	end

	cd(CurrentDir)

	OutputDirectory=string(pwd(),"/","ConnectedComponents.txt")

elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirPolyMesh\\connected_components_example.exe")) 
	println(Exe)


	str1="$Exe '$SurfaceDir' | out-file -Encoding ascii 'ConnectedComponents.txt'" 
	RunConnectedComponents=split("powershell $str1")
	try
		run(`$RunConnectedComponents`);
	catch
		println("Connected component finding failed")
	end

	OutputDirectory=string(pwd(),"\\","ConnectedComponents.txt")

end

return OutputDirectory

end