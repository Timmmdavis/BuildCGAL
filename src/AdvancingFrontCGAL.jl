function AdvancingFrontCGAL(PointsDir)


if Sys.islinux()
	
	println("To do")

elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirAdvFront\\reconstruction_surface_mesh.exe")) 
	println(Exe)

	str1="$Exe '$PointsDir' | out-file -Encoding ascii 'AdvancingFrontMeshed.off'"
	RunAdvFront=split("powershell $str1")
	try
		run(`$RunAdvFront`);
	catch
		println("Advancing front reconstruction failed")
	end

	OutputDirectory=string(pwd(),"\\","AdvancingFrontMeshed.off")

end


return OutputDirectory

end