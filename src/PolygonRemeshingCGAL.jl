function PolygonRemeshingCGAL(SurfaceDir,target_edge_length)


if Sys.islinux()
	
	println("To do")

elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirPolyMesh\\isotropic_remeshing_example.exe")) 
	println(Exe)

	str1="$Exe '$SurfaceDir' $target_edge_length | out-file -Encoding ascii 'remeshed.off'"
	RunPolygonRemesh=split("powershell $str1")
	println(RunPolygonRemesh)
	try
		run(`$RunPolygonRemesh`)
	catch
		println("Polygon remeshing failed")
	end

	Outputdirectory=string(pwd(),"\\","remeshed.off")

end


return Outputdirectory

end