#build.jl - define function first
function SetEnviromentVarWindows(BinPath)
	#bin path being somthing like :GccBinPath=raw"C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\bin"

	#first check the directory actually exists:
	TestPath=split("powershell ;")
	TestPath[end]=string("Test-Path -Path '","$BinPath","'"," | out-file -Encoding ascii 'test.txt'")
	run(`$TestPath`)
	io=open("test.txt","r");
	PathExists=readline(io)=="True"
	close(io)
	if PathExists==false
		error("Did you install to the default install directory? Tried to add path $BinPath but it doesnt exist")
	end

	#then add the env var
	SetEnviromentVar=split("powershell ;")
	SetEnviromentVar[end]="[Environment]::SetEnvironmentVariable("
	P2="PATH"
	P3=raw"$ENV"
	P4=":PATH;"
	P5="User"
	SetEnviromentVar[end]=string(SetEnviromentVar[end],'"',P2,'"',',','"',P3,P4,"$BinPath",'"',',','"',P5,'"',')')
	println(SetEnviromentVar[end]) #actual cmd
	run(`$SetEnviromentVar`)
end


#Run build process
using BuildCGAL
#Jump to correct dir
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

	#TEST FOR DEPS
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
	#@everywhere push!(LOAD_PATH,"/path/to/my/code") #? try this instead - need to get the env var in there somehow

elseif Sys.iswindows()

	(GccExists,MakeExists,CMakeExists,BoostPathIsGood,CGALPathIsGood)=BuildCGAL.test4deps()
	

	if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
		
		println("deps have been installed already - just run BuildCGAL.SetupCGAL()")

	else
		#test FireFox is installed so we can download:
		QueryAdmin=split(raw"powershell ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') | out-file -Encoding ascii 'test.txt'")
		run(`$QueryAdmin`)
		io=open("test.txt","r");		
		AdminTrue=readline(io)=="True"
		close(io)
		if AdminTrue==false
			error("you need to run Julia as an admin to get the paths to work...")
		end

		#test FireFox is installed so we can download:
		QueryFireFox=split(raw"powershell Test-Path 'HKLM:\SOFTWARE\Mozilla\Mozilla Firefox' | out-file -Encoding ascii 'test.txt'")
		run(`$QueryFireFox`)
		io=open("test.txt","r");		
		FirefoxExists=readline(io)=="True"
		close(io)
		if FirefoxExists==false
			error("install Firefox before running build")
		end

		#Setting a variable in powershell:
		#Set-Variable -Name "LinkLoc" -Value "https://downloads.sourceforge.net/project/gnuwin32/make/3.81/make-3.81.exe"
		

		if MakeExists==false
			println("Downloading Make")
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
			wait_for_key("Finished with Dialog? press enter to continue...")


			#Set the Environment variables
			MakeBinPath=raw"C:\Program Files (x86)\GnuWin32\bin"
			SetEnviromentVarWindows(MakeBinPath)

		end

		if CMakeExists==false
			println("Downloading CMake")
			#Install CMAKE
			#https://github.com/JuliaPackaging/CMake.jl/tree/5985636ac494ac2e22c19c282e54f65e7bbc7ad9
			io=open("cmakepath.txt","r");
			cmake=readline(io) #path2 cmake
			close(io)
			println(cmake) #path of the cmake build
			#remove the actual .exe tag on the end (we just want the bin path not the file)
			cmakesplit=splitdir(cmake);
			CMakeBinPath=cmakesplit[1] 
			SetEnviromentVarWindows(CMakeBinPath)	

		end

		if GccExists==false
			println("Downloading Gcc")
			#Download gcc64
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2GccExe="https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download"
			DownloadFile=("Invoke-WebRequest -Uri $Link2GccExe -O mingw-w64-install.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
			DownloadGcc=split(string(SetSecurityProfile,";",DownloadFile))
			run(`$DownloadGcc`)
			println("Downloaded mingw-w64-install.exe to $BuildDir")

			#gcc64 should now be downloaded in current folder - now we install it
			println("you will get a gcc dialog here - use defaults")
			RunInstall=split("powershell ./mingw-w64-install.exe")
			run(`$RunInstall`)
			wait_for_key("Finished with GCC Dialog? press enter to continue...")

			#Set the Environment variables
			GccBinPath=raw"C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\bin"
			SetEnviromentVarWindows(GccBinPath)
			GccBinPath2=raw"C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\opt\bin"
			SetEnviromentVarWindows(GccBinPath2)	

		end	

		if BoostPathIsGood==false
			println("Downloading Boost")
			#Download boost files
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2BoostFiles="https://dl.bintray.com/boostorg/release/1.68.0/source/boost_1_68_0.7z"
			DownloadFile=("Invoke-WebRequest -Uri $Link2BoostFiles -O boost_1_68_0.7z -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
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
			wait_for_key("Wait for popup to finish, then press enter to continue...")			
			CreateBoost2=split("powershell ./b2.exe toolset=gcc")
			run(`$CreateBoost2`)
			cd("BuildDir")

			#Set the Environment variables
			BoostPath=raw"C:\boost_1_70_0"
			SetEnviromentVarWindows(BoostPath)
			BoostPath2=raw"C:\boost_1_70_0\bin.v2"
			SetEnviromentVarWindows(BoostPath2)	

		end			

		if CGALPathIsGood==false
			println("Downloading CGAL")
			#Download boost files
			SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			Link2CGAL="https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe"
			DownloadFile=("Invoke-WebRequest -Uri $Link2CGAL -O CGAL-4.13.1-Setup.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
			DownloadCGAL=split(string(SetSecurityProfile,";",DownloadFile))
			run(`$DownloadCGAL`)
			println("Downloaded CGAL-4.13.1-Setup.exe to $BuildDir")

			#gcc64 should now be downloaded in current folder - now we install it
			println("you will get a CGAL dialog here - use defaults")
			RunInstall=split("powershell ./CGAL-4.13.1-Setup.exe")
			run(`$RunInstall`)
			wait_for_key("Finished with CGAL Dialog? press enter to continue...")

			#Set the Environment variable
			CGALPath=raw"C:\dev\CGAL-4.13.1"
			SetEnviromentVarWindows(CGALPath)
			CGALPath2=raw"C:\dev\CGAL-4.13.1\auxiliary\gmp\lib"
			SetEnviromentVarWindows(CGALPath2)	#Set the Environment variables

		end				

	end #deps exists statement

	println("Deps etc should now be installed - restart julia then rerun SetupCGAL")

elseif Sys.isapple
		error("Not supported, check linux implementation?")
end
