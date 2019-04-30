Getting CGAL working on Windows
1. CMAKE
Download the msi installer here:
https://cmake.org/download/ 
https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1-win64-x64.msi
Run and follow instructions, install for all users (on path)
Enviroment var should exist - C:\Program Files\CMake\bin #check with powershell - 'CMake'

2. GnuWin32
http://gnuwin32.sourceforge.net/packages/make.htm
Install 
Enviroment var should exist - C:\Program Files (x86)\GnuWin32\bin #check with powershell - 'make'

3. MinGW64
https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download
defaults, i686 etc
add 
C:\Program Files (x86)\mingw-w64\i686-7.3.0-posix-dwarf-rt_v5-rev0\mingw32\bin
and
C:\Program Files (x86)\mingw-w64\i686-7.3.0-posix-dwarf-rt_v5-rev0\mingw32\opt\bin
to path
Install with defaults

4. CGAL
Download installer:
https://github.com/CGAL/cgal/releases
https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe
Run and follow instructions, install for all users (on path). I used 32bit version.
Add 
C:\dev\CGAL-4.13.1
and
C:\dev\CGAL-4.13.1\auxiliary\gmp\lib
to path 


5. Try using 'CMake .' in Powershell. If fails check you have installed all prerequisites here:
"C:\dev\CGAL-4.13.1\INSTALL.md"

i.e. Boost error:
Download Boost:
https://www.boost.org/doc/libs/1_70_0/more/getting_started/windows.html
Paste into Cdrive
Then run with admin privs(Should take a while so dont hold your breath):
C:\boost_1_70_0\bootstrap.bat
>> ./b2 toolset=gcc #(or whatever b2 command you need)
add2path - C:\boost_1_70_0 && C:\boost_1_70_0\bin.v2


6. Now building GCAL parts on windows:

	1. open the CMAKE GUI - choose new build folder location
	2. run configure - choose default MinGW makefile in configure
	3. run configure again (might need to set relase flag). Also check we point to correct libaries (not julia ones)
	4. run build (if there are requested components in the text output install these!)
	5. now in the build folder run powershell - 'make'
	6. if error on only certain files just change .cpp ending so they dont make

	without Cmake GUI - go to dir with "CMakeLists.txt" and ".cpp" files
	>> cmake . -G "MinGW Makefiles" -D "CMAKE_BUILD_TYPE=Release"
	>> make
	now you should have exes you can run