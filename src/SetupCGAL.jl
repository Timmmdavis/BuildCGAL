function SetupCGAL()

if Sys.islinux()
	#Check bits and call from thing

elseif Sys.iswindows()

	#Check objects are callable (on path)
	#Call shell script that checks exe is callable and the version and writes to a txt file 
	#we then read file and check if its the right version

	#MinGW mingw-w64\i686-7.3.0-posix-dwarf-rt_v5-rev0	
	#https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download
	testgcc=split(raw"powershell gcc --version | out-file -Encoding ascii 'test.txt'")
	run(`$testgcc`)
	io=open("test.txt","r");
	GccExists=readline(io)=="gcc.exe (i686-posix-dwarf-rev0, Built by MinGW-W64 project) 7.3.0"
	close(io)

	#Make 3.81 http://gnuwin32.sourceforge.net/packages/make.htm
	testmake=split(raw"powershell make --version | out-file -Encoding ascii 'test.txt'")
	run(`$testmake`)
	io=open("test.txt","r");	
	MakeExists=readline(io)=="GNU Make 3.81"	
	close(io)		

	#CMake 3.14.1 https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1-win64-x64.msi
	testCmake=split(raw"powershell CMake --version | out-file -Encoding ascii 'test.txt'")
	run(`$testCmake`)
	io=open("test.txt","r");		
	CMakeExists=readline(io)=="cmake version 3.14.1"
	close(io)		
	rm("test.txt")#Remove output		


	#Check paths of non callable objects:
	#CGAL 4.13.1 https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe
	CGALPathIsGood=Base.Filesystem.ispath(raw"C:\dev\CGAL-4.13.1")
	#https://www.boost.org/doc/libs/1_70_0/more/getting_started/windows.html
	BoostPathIsGood=Base.Filesystem.ispath(raw"C:\boost_1_70_0\bin.v2")

	#build scripts inside directory
	if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
		println("Dependancies have been met, attempting to run build")


		println("Would be good to functionise parts below:")

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


		println("Check .exes dont already exist (i.e. already run)")
		if isfile("boundaries.exe") && isfile("reconstruction_class.exe") && 
		isfile("reconstruction_fct.exe") && isfile("reconstruction_structured.exe") &&
		isfile("reconstruction_surface_mesh.exe")
			println("exe's already pre-built, skipping build")

		else
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

		println("read and follow 'Getting Gcal working on Windows.md' to link deps before proceeding")
		#install each dependancy as we go
		#catch errors and report
		#ask user to rerun after these have been met
	end


elseif Sys.isapple
	error("Not supported, check linux implementation?")
end


end



