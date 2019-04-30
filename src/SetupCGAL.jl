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

	if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
		println("Things are looking promising")
		#build scripts inside directory
		#run and test...
	else
		#install each one as we go
		#catch errors and report
	end


elseif Sys.isapple
	error("Not supported, check linux implementation?")
end


end



