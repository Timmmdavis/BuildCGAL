function test4deps()

#Check objects are callable (on path)
#Call shell script that checks exe is callable and the version and writes to a txt file 
#we then read file and check if its the right version

#MinGW mingw-w64\i686-7.3.0-posix-dwarf-rt_v5-rev0	
#https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download
testgcc=split(raw"powershell gcc --version | out-file -Encoding ascii 'test.txt'")
desiredstring="gcc.exe (i686-posix-dwarf-rev0, Built by MinGW-W64 project) 8.1.0"
(GccExists)=TryRunFromPowershell(testgcc,desiredstring)

#Make 3.81 http://gnuwin32.sourceforge.net/packages/make.htm
testmake=split(raw"powershell make --version | out-file -Encoding ascii 'test.txt'")
desiredstring="GNU Make 3.81"
(MakeExists)=TryRunFromPowershell(testmake,desiredstring)	

#CMake 3.14.1 https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1-win64-x64.msi
testCmake=split(raw"powershell CMake --version | out-file -Encoding ascii 'test.txt'")
desiredstring="cmake version 3.14.1"
(CMakeExists)=TryRunFromPowershell(testCmake,desiredstring)	

#Check paths of non callable objects:
#https://www.boost.org/doc/libs/1_70_0/more/getting_started/windows.html
BoostPathIsGood=Base.Filesystem.ispath(raw"C:\boost_1_70_0\bin.v2")
#CGAL 4.13.1 https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe
CGALPathIsGood=Base.Filesystem.ispath(raw"C:\dev\CGAL-4.13.1")

test=1;
@info test GccExists MakeExists CMakeExists BoostPathIsGood CGALPathIsGood


return GccExists,MakeExists,CMakeExists,BoostPathIsGood,CGALPathIsGood
end


function TryRunFromPowershell(runexestring,desiredstring) 
try
	#remove file we write to if it exists
	if isfile("test.txt")
		rm("test.txt")
	end
	run(`$runexestring`)
	io=open("test.txt","r");
	Exists=readline(io)=="$desiredstring"
	close(io)
	return Exists
catch
	Exists=false
	return Exists
end
end



