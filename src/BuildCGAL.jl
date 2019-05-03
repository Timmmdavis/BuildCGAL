module BuildCGAL
using CMake


#export cmake dir as text file
str=split(string("powershell Write-Output"," $cmake | out-file -Encoding ascii 'cmakepath.txt'"))
run(`$str`)

#func def so we can wait for users key promt
wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)

#functions we export
include("SetupCGAL.jl")
include("test4deps.jl")

end # module
