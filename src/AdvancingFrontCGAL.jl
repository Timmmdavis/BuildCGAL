function AdvancingFrontCGAL(PointsDir)


if Sys.islinux()
	
	println("To do")

elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(ModuleName))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirAdvFront\\reconstruction_surface_mesh.exe")) 

	str1="./$Exe $PointsDir | out-file -Encoding ascii 'meshed.off'"
	RunAdvFront=split("powershell $str1")
	try
		run(`$RunAdvFront`)
	catch
		println("Advancing front reconstruction failed")
	end

	Outputdirectory=splitdir(Exe)[]

end


return Outputdirectory

end