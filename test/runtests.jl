#
# Correctness Tests
#

using Test 
using BuildCGAL

fatalerrors = length(ARGS) > 0 && ARGS[1] == "-f"
quiet = length(ARGS) > 0 && ARGS[1] == "-q"
anyerrors = false


my_tests = ["AdvancingFrontTest.jl"]    
			
println("Running tests:")

for my_test in my_tests
    try
        println("\t\033[1m\033[32mStarting\033[0m: $(my_test)")
        include(my_test)
        println("\t\033[1m\033[32mPASSED\033[0m: $(my_test)")
    catch e
        global anyerrors = true
        println("\t\033[1m\033[31mFAILED\033[0m: $(my_test)")
        if fatalerrors
            rethrow(e)
        elseif !quiet
            showerror(stdout, e, backtrace())
            println()
        end
    end
end

if anyerrors
    throw("Tests failed")
end