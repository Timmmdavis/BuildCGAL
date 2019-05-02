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
	#Check bits and call from thing


	error("Test this works")
	#sudo apt-get install libcgal-dev #easy way -gets the deps too 
	#run(`sudo apt-get install libcgal-dev`)
	#sudo apt-get --purge remove libcgal-dev #remove old builds
	run(`mkdir CGAL-4.13.1`)
	cd(string(pwd(),"/CGAL-4.13.1"))
	run(`wget https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1.tar.xz`)
	run(`7z x CGAL-4.13.1.tar.xz`)
	run(`7z x CGAL-4.13.1.tar`)
	cd(string(pwd(),"/CGAL-4.13.1"))
	run(`cmake .`)
	run(`make`)

	error("This bit doesnt work at the moment")
	CGALpath1=string(ModuleDir,"/CGAL-4.13.1/CGAL-4.13.1")
	CGALpath2=string(ModuleDir,"/CGAL-4.13.1/CGAL-4.13.1/aux/gmp/lib")
	str1=raw"export PATH=${PATH}:"
	addpath=string(str1,"$CGALpath1")
	addpath2=string(str1,"$CGALpath2")
	run(`$addpath`)
	run(`$addpath2`)
	@everywhere push!(LOAD_PATH,"/path/to/my/code") #? try this instead - need to get the env var in there somehow

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
	
	#Check paths of non callable objects:
	#https://www.boost.org/doc/libs/1_70_0/more/getting_started/windows.html
	BoostPathIsGood=Base.Filesystem.ispath(raw"C:\boost_1_70_0\bin.v2")
	#CGAL 4.13.1 https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe
	CGALPathIsGood=Base.Filesystem.ispath(raw"C:\dev\CGAL-4.13.1")





	#build scripts inside directory
	if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
		println("Dependancies have been met, attempting to run build")


		println("Check .exes dont already exist (i.e. already run)")
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

		#test FireFox is installed so we can download:
		QueryFireFox=split(raw"powershell Test-Path 'HKLM:\SOFTWARE\Mozilla\Mozilla Firefox' | out-file -Encoding ascii 'test.txt'")
		run(`$QueryFireFox`)
		io=open("test.txt","r");		
		FirefoxExists=readline(io)=="True"
		if FirefoxExists==false
			error("install Firefox")
		end

		#Setting a variable in powershell:
		#Set-Variable -Name "LinkLoc" -Value "https://downloads.sourceforge.net/project/gnuwin32/make/3.81/make-3.81.exe"
		

		if MakeExists==false

			#Download make:
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2MakeExe="https://downloads.sourceforge.net/project/gnuwin32/make/3.81/make-3.81.exe"
			DownloadFile=("Invoke-WebRequest -Uri $Link2MakeExe -O make-3.81.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
			DownloadMake=split(string(SetSecurityProfile,";",DownloadFile))
			run(`$DownloadMake`)
			println("Downloaded make-3.81.exe to $BuildDir")
			
			#Make should now be downloaded in current folder - now we install it
			RunInstall=split("powershell ./make-3.81.exe /VERYSILENT /SUPPRESSMSGBOXES")
			println("Unless you have admin privs you will get a dialog here from windows")
			run(`$RunInstall`)
			wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)
			wait_for_key("Finished with Dialog? press enter to continue...")


			#Set the Environment variables
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			MakeBinPath=raw"C:\Program Files (x86)\GnuWin32\bin"
			EndOfString=string(raw"'$ENV:PATH;","$MakeBinPath","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)

		end

		if CMakeExists==false

			#Install CMAKE
			#https://github.com/JuliaPackaging/CMake.jl/tree/5985636ac494ac2e22c19c282e54f65e7bbc7ad9
			Pkg.add("CMake")
			using CMake
			println(cmake) #path of the cmake build
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			cmakesplit=splitdir(cmake);
			CMakeBinPath=cmakesplit[1]
			EndOfString=string(raw"'$ENV:PATH;","$CMakeBinPath","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)

		end

		if GccExists==false

			#Download gcc64
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2GccExe="https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download"
			DownloadFile=("Invoke-WebRequest -Uri $Link2GccExe -O make-3.81.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
			DownloadGcc=split(string(SetSecurityProfile,";",DownloadFile))
			run(`$DownloadGcc`)
			println("Downloaded mingw-w64-install.exe to $BuildDir")

			#gcc64 should now be downloaded in current folder - now we install it
			println("you will get a gcc dialog here - use defaults")
			RunInstall=split("powershell ./mingw-w64-install.exe")
			run(`$RunInstall`)
			wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)
			wait_for_key("Finished with GCC Dialog? press enter to continue...")

			#Set the Environment variables
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			MakeBinPath=raw"C:\MinGW\bin"
			EndOfString=string(raw"'$ENV:PATH;","$MakeBinPath","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)

		end	

		if BoostPathIsGood==false

			#Download boost files
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2BoostFiles="https://dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.7z"
			DownloadFile=("Invoke-WebRequest -Uri $Link2BoostFiles -O make-3.81.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
			DownloadBoost=split(string(SetSecurityProfile,";",DownloadFile))
			run(`$DownloadBoost`)
			println("Downloaded boost_1_68_0.7z to $BuildDir")

			#7z should be on path (comes with julia)
			ExtractBoost=split(raw"powershell 7z x .\boost_1_70_0.zip -oboost_1_70_0")
			run(`$ExtractBoost`)

			#Now build it 
			BoostDir=string(ModuleDir,string("\\boost_1_70_0\\boost_1_70_0\\")) 
			cd("BoostDir")
			CreateBoost1=split("powershell ./bootstrap.sh")
			run(`$CreateBoost1`)
			wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)
			wait_for_key("Wait for popup to finish, then press enter to continue...")			
			CreateBoost2=split("powershell ./b2.exe toolset=gcc")
			run(`$CreateBoost2`)
			cd("BuildDir")

			#Set the Environment variables
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			BoostPath=raw"C:\boost_1_70_0"
			EndOfString=string(raw"'$ENV:PATH;","$BoostPath","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			BoostPath2=raw"C:\boost_1_70_0\bin.v2"
			EndOfString=string(raw"'$ENV:PATH;","$BoostPath2","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)

		end			

		if CGALPathIsGood==false

			#Download boost files
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2CGAL="https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe"
			DownloadFile=("Invoke-WebRequest -Uri $Link2CGAL -O make-3.81.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
			DownloadCGAL=split(string(SetSecurityProfile,";",DownloadFile))
			run(`$DownloadCGAL`)
			println("Downloaded CGAL-4.13.1-Setup.exe to $BuildDir")

			#gcc64 should now be downloaded in current folder - now we install it
			println("you will get a CGAL dialog here - use defaults")
			RunInstall=split("powershell ./CGAL-4.13.1-Setup.exe")
			run(`$RunInstall`)
			wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)
			wait_for_key("Finished with CGAL Dialog? press enter to continue...")

			#Set the Environment variables
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			CGALPath=raw"C:\dev\CGAL-4.13.1"
			EndOfString=string(raw"'$ENV:PATH;","$CGALPath","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)
			SetEnviromentVar=split("powershell [Environment]::SetEnvironmentVariable('PATH',")
			CGALPath2=raw"C:\dev\CGAL-4.13.1\auxiliary\gmp\lib"
			EndOfString=string(raw"'$ENV:PATH;","$CGALPath2","'",",'User')")
			SetEnviromentVar[end]=string(SetEnviromentVar[end],"$EndOfString")
			SetEnviromentVar[end]=replace(SetEnviromentVar[end], "'" => '"') #Needs " not ' to work 
			run(`$SetEnviromentVar`)


		end				



		println("Deps etc should now be installed - rerun SetupCGAL")
		#install each dependancy as we go
		#catch errors and report
		#ask user to rerun after these have been met
	end


elseif Sys.isapple
	error("Not supported, check linux implementation?")
end


rm("test.txt")#Remove output	

end



