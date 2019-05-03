function SetupCGAL()

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


if Sys.islinux()

	#TEST FOR DEPS
	#Run make


elseif Sys.iswindows()


	(GccExists,MakeExists,CMakeExists,BoostPathIsGood,CGALPathIsGood)=test4deps()

	#build scripts inside directory
	if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
		println("Dependancies have been met, attempting to run build")


		println("Checking if the .exes already exist (i.e. this has already run)")
		if isfile("boundaries.exe") && isfile("reconstruction_class.exe") && 
			isfile("reconstruction_fct.exe") && isfile("reconstruction_structured.exe") &&
			isfile("reconstruction_surface_mesh.exe")

			println("exe's already pre-built, skipping build")

		else


			println("Would be good to functionise parts below:")

			println("Begin build")
			str1="powershell cmake . -B$BuildDir -H$CMakeListDir -G 'MinGW Makefiles'"
			strfnt="-D "
			str2="'CMAKE_BUILD_TYPE=Release'"
			str3=raw"GMP_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include "
			str4=raw"GMP_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libgmp-10.dll "
			str5=raw"GMP_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib " 
			str6=raw"MPFR_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include "
			str7=raw"MPFR_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libmpfr-4.dll "
			str8=raw"MPFR_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib " 
			RunCMake=string(str1,strfnt,str2,strfnt,str3,strfnt,str4,strfnt,str5,strfnt,str6,strfnt,str7,strfnt,str8)
			println(RunCMake)
			RunCMake=split(RunCMake)
			#explict with the GMP and MPFR libs or they get mixed with those from Julia env var
			#cmake -help #for options
			#println(RunCMake)
			run(`$RunCMake`)

			RunMake=split("powershell make -C$BuildDir")
			#make -help #for options
			#println(RunCMake)
			run(`$RunMake`)
		end

		#now run and test...

	else

		error("Requires dependencies that you dont have installed, run include-build.jl \n make sure you have firefox installed and use admin rights")

	end


elseif Sys.isapple

	error("Not supported, check linux implementation?")

end


if isfile("test.txt")
	rm("test.txt")
end

end



