function Compile_CGAL_Meshing_Functions()

ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]

#upper directory
CMakeListDir=string(ModuleDir,string("\\examples\\Advancing_front_surface_reconstruction\\")) 
CMakeListDir2=string(ModuleDir,string("\\examples\\Polygon_mesh_processing\\")) 
#where we will build our stuff
BuildDirAdvancingFront=string(ModuleDir,string("\\examples\\BuildDirAdvFront\\")) 
BuildDirPolygonMesh=string(ModuleDir,string("\\examples\\BuildDirPolyMesh\\")) 
cd(BuildDir)


if Sys.islinux()

	#TEST FOR DEPS
	#Run make


elseif Sys.iswindows()


	(GccExists,MakeExists,CMakeExists,BoostPathIsGood,CGALPathIsGood)=test4deps()

	#build scripts inside directory
	#if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
		println("Dependancies have been met, attempting to run build")


		strfnt="-D"
		str2="'CMAKE_BUILD_TYPE=Release'"	
		str3=raw"GMP_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include/ "
		str4=raw"GMP_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libgmp-10.dll "
		str5=raw"GMP_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/ " 
		str6=raw"MPFR_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include/ "
		str7=raw"MPFR_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libmpfr-4.dll "
		str8=raw"MPFR_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib " 


		
		#ADVANCING FRONT
		println("Checking if the .exes already exist (i.e. this has already run)")
		if isfile("boundaries.exe") && isfile("reconstruction_class.exe") && 
			isfile("reconstruction_fct.exe") && isfile("reconstruction_structured.exe") &&
			isfile("reconstruction_surface_mesh.exe")

			println("exe's already pre-built, skipping build")

		else


			println("Begin build")
			str1="powershell cmake . -B$BuildDirAdvancingFront -H$CMakeListDir -G 'MinGW Makefiles'"

			RunCMake=string(str1,strfnt,str2,strfnt,str3,strfnt,str4,strfnt,str5,strfnt,str6,strfnt,str7,strfnt,str8)
			println(RunCMake)
			RunCMake=split(RunCMake)
			#explict with the GMP and MPFR libs or they get mixed with those from Julia env var cmake -help #for options
			run(`$RunCMake`)
			RunMake=split("powershell make -C$BuildDirAdvancingFront")
			#make -help #for options
			#println(RunCMake)
			try
				run(`$RunMake`)
			catch
				println("Make build.jl has been run and all the enviroment vars set in this point to folders")
			end
		end
		

		#Polygon_mesh_processing
		println("Checking if the .exes already exist (i.e. this has already run)")
		test=0;
		if test==1;

			println("exe's already pre-built, skipping build")

		else


			println("Begin build")
			str1="powershell cmake . -B$BuildDirPolygonMesh -H$CMakeListDir2 -G 'MinGW Makefiles'"

			RunCMake=string(str1,strfnt,str2,strfnt,str3,strfnt,str4,strfnt,str5,strfnt,str6,strfnt,str7,strfnt,str8)
			println(RunCMake)
			RunCMake=split(RunCMake)
			#explict with the GMP and MPFR libs or they get mixed with those from Julia env var cmake -help #for options
			run(`$RunCMake`)
			RunMake=split("powershell make -C$BuildDirPolygonMesh")
			#make -help #for options
			#println(RunCMake)
			try
				run(`$RunMake`)
			catch
				println("Make build.jl has been run and all the enviroment vars set in this point to folders")
			end
		end

		#now run and test...

	#else

	#	error("Requires dependencies that you dont have installed, run include-build.jl \n make sure you have firefox installed and use admin rights")

	#end


elseif Sys.isapple

	error("Not supported, check linux implementation?")

end


if isfile("test.txt")
	rm("test.txt")
end

end



