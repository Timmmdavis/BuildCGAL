function AdvancingFrontCGAL(PointsDir)


if Sys.islinux()
	
	println("To do")

elseif Sys.iswindows()

	ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
	Exe=string(ModuleDir,string("\\examples\\BuildDirAdvFront\\reconstruction_surface_mesh.exe")) 
	println(Exe)

	#https://doc.cgal.org/latest/Advancing_front_surface_reconstruction/group__PkgAdvancingFrontSurfaceReconstructionRef.html
	#Can change the radius_ratio_bound and beta here if wanted:
	radius_ratio_bound=5;
	beta=0.52

	str1="$Exe '$PointsDir' $radius_ratio_bound $beta | out-file -Encoding ascii 'AdvancingFrontMeshed.off'" 
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