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
	#https://stackoverflow.com/questions/714877/setting-windows-powershell-environment-variables#1333717
	SetEnviromentVar=split("powershell ;")
	SetEnviromentVar[end]="[Environment]::SetEnvironmentVariable("
	GetEnviromentVar="[Environment]::GetEnvironmentVariable("
	P2=raw"'Path',"
	P4="[EnvironmentVariableTarget]::User)"
	P5="+"
	P6=raw"'"
	SetEnviromentVar[end]=string(SetEnviromentVar[end],P2,GetEnviromentVar,P2,P4,P5,P6,";","$BinPath",P6,",",P4)
	#SetEnviromentVar[end]=string(SetEnviromentVar[end],'"',P2,'"',',','"',P3,P4,"$BinPath",'"',',','"',P5,'"',')')
	println(SetEnviromentVar[end]) #actual cmd
	run(`$SetEnviromentVar`)



	println("Sleeping for 15")
	sleep(15)


end