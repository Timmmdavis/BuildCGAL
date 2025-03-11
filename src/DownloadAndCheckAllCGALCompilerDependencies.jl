#Paths that will exist
#=
C:\Program Files (x86)\GnuWin32\bin
C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\bin
C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\opt\bin
C:\boost_1_70_0
C:\boost_1_70_0\bin.v2
C:\dev\CGAL-4.13.1
C:\dev\CGAL-4.13.1\auxiliary\gmp\lib
CMAKE PATH  C:\Users\timmm\.julia\packages\CMake\..............\deps\downloads\cmake-3.12.3-win64-x64\bin
=#

#Run build process
using BuildCGAL

#Jump to correct dir
ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
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

			if isfile("make-3.81.exe")==false
				println("Downloading Make")
				#Download make:
				SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
				Link2MakeExe="https://downloads.sourceforge.net/project/gnuwin32/make/3.81/make-3.81.exe"
				DownloadFile=("Invoke-WebRequest -Uri $Link2MakeExe -O make-3.81.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
				DownloadMake=split(string(SetSecurityProfile,";",DownloadFile))
				run(`$DownloadMake`)
				println("Downloaded make-3.81.exe to $BuildDir")
			end

			#Make should now be downloaded in current folder - now we install it
			RunInstall=split("powershell ./make-3.81.exe /VERYSILENT /SUPPRESSMSGBOXES")
			println("Unless you have admin privs you will get a dialog here from windows")
			run(`$RunInstall`)
			BuildCGAL.wait_for_key("Finished with Dialog? press enter to continue...")

			println("Sleeping for 10")
			sleep(10)
			
			#Set the Environment variables
			MakeBinPath=raw"C:\Program Files (x86)\GnuWin32\bin"
			BuildCGAL.SetEnviromentVarWindows(MakeBinPath)

		end

		if CMakeExists==false

			#Install CMAKE
			#https://github.com/JuliaPackaging/CMake.jl/tree/5985636ac494ac2e22c19c282e54f65e7bbc7ad9
			io=open("cmakepath.txt","r");
			cmake=readline(io) #path2 cmake
			close(io)
			println(cmake) #path of the cmake build
			#remove the actual .exe tag on the end (we just want the bin path not the file)
			cmakesplit=splitdir(cmake);
			CMakeBinPath=cmakesplit[1] 
			BuildCGAL.SetEnviromentVarWindows(CMakeBinPath)	

		end

		if GccExists==false

			if isfile("mingw-w64-install.exe")==false
				println("Downloading Gcc")
				#Download gcc64
				SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
				Link2GccExe="https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/installer/mingw-w64-install.exe/download"
				DownloadFile=("Invoke-WebRequest -Uri $Link2GccExe -O mingw-w64-install.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
				DownloadGcc=split(string(SetSecurityProfile,";",DownloadFile))
				run(`$DownloadGcc`)
				println("Downloaded mingw-w64-install.exe to $BuildDir")
			end

			#gcc64 should now be downloaded in current folder - now we install it
			println("you will get a gcc dialog here - use defaults")
			RunInstall=split("powershell ./mingw-w64-install.exe")
			run(`$RunInstall`)
			println("If the dialog below fails - install using ")
			BuildCGAL.wait_for_key("Finished with GCC Dialog? type a key, delete it, press enter to continue...")
			
			println("Sleeping for 10")
			sleep(10)

			#Set the Environment variables
			GccBinPath=raw"C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\bin"
			BuildCGAL.SetEnviromentVarWindows(GccBinPath)
			GccBinPath2=raw"C:\Program Files (x86)\mingw-w64\i686-8.1.0-posix-dwarf-rt_v6-rev0\mingw32\opt\bin"
			BuildCGAL.SetEnviromentVarWindows(GccBinPath2)	
			
			println("I personally had issues with the mingw download (dialog then nothing happened), to get around I installed https://www.msys2.org/ then After installation, use the package manager to install MinGW: pacman -S mingw-w64-i686-toolchain. Go with the defaults and install everything. Check it runs in powershell using gcc –version, make sure the C:/msys64/mingw32/bin its on the path")
			BuildCGAL.wait_for_key("Checked? press enter to continue...")

		end	
		
		if BoostPathIsGood==false

			if isfile("boost_1_70_0.zip")==false
				println("Downloading Boost")
				#Download boost files
			    SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
			    Link2BoostFiles="https://sourceforge.net/projects/boost/files/boost/1.70.0/boost_1_70_0.zip/download"
				DownloadFile=("Invoke-WebRequest -Uri $Link2BoostFiles -O boost_1_70_0.zip -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
				DownloadBoost=split(string(SetSecurityProfile,";",DownloadFile))
				run(`$DownloadBoost`)
				println("Downloaded boost_1_70_0.zip to $BuildDir")
			end

			#7z should be on path (comes with julia)
			ExtractBoost=split(raw"powershell 7z x .\boost_1_70_0.zip -oC:\\")
			run(`$ExtractBoost`)

			#Now build it 
			BoostDir="C:\\boost_1_70_0"
			cd("$BoostDir")
			CreateBoost1=split("powershell ./bootstrap.bat gcc")
			run(`$CreateBoost1`)

			BuildCGAL.wait_for_key("Wait for popup to finish, then press enter to continue...")		

			println("Sleeping for 10")
			sleep(10)

			CreateBoost2=split("powershell ./b2.exe toolset=gcc")
			try run(`$CreateBoost2`)
			catch
			end
			println("Sleeping for 10")
			sleep(10)

			cd("$BuildDir")

			#Set the Environment variables
			BoostPath=raw"C:\boost_1_70_0"
			BuildCGAL.SetEnviromentVarWindows(BoostPath)		
			BoostPath2=raw"C:\boost_1_70_0\bin.v2"
			BuildCGAL.SetEnviromentVarWindows(BoostPath2)	

		end			
		

		if CGALPathIsGood==false

			if isfile("CGAL-4.13.1-Setup.exe")==false
				println("Downloading CGAL")
				#Download boost files
				SetSecurityProfile=(raw"powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12")
				Link2CGAL="https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.13.1/CGAL-4.13.1-Setup.exe"
				DownloadFile=("Invoke-WebRequest -Uri $Link2CGAL -O CGAL-4.13.1-Setup.exe -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox")
				DownloadCGAL=split(string(SetSecurityProfile,";",DownloadFile))
				run(`$DownloadCGAL`)
				println("Downloaded CGAL-4.13.1-Setup.exe to $BuildDir")
			end

			#gcc64 should now be downloaded in current folder - now we install it
			println("you will get a CGAL dialog here - use defaults 32BIT")
			RunInstall=split("powershell ./CGAL-4.13.1-Setup.exe")
			run(`$RunInstall`)
			BuildCGAL.wait_for_key("Finished with CGAL Dialog? press enter to continue...")
			
			println("Sleeping for 10")
			sleep(10)

			#Set the Environment variable
			CGALPath=raw"C:\dev\CGAL-4.13.1"
			BuildCGAL.SetEnviromentVarWindows(CGALPath)
			CGALPath2=raw"C:\dev\CGAL-4.13.1\auxiliary\gmp\lib"
			BuildCGAL.SetEnviromentVarWindows(CGALPath2)	#Set the Environment variables

		end				

	end #deps exists statement

	println("Deps etc should now be installed - restart julia then rerun SetupCGAL")

elseif Sys.isapple
		error("Not supported, check linux implementation?")
end
