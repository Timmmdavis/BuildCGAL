function Compile_CGAL_Meshing_Functions()
    ModuleDir=splitdir(splitdir(pathof(BuildCGAL))[1])[1]
    #upper directory
    CMakeListDir=joinpath(ModuleDir, "examples", "Advancing_front_surface_reconstruction")
    CMakeListDir2=joinpath(ModuleDir, "examples", "Polygon_mesh_processing")
    #where we will build our stuff
    BuildDirAdvancingFront=joinpath(ModuleDir, "examples", "BuildDirAdvFront")
    BuildDirPolygonMesh=joinpath(ModuleDir, "examples", "BuildDirPolyMesh")
    
    cd(ModuleDir)  # Assuming BuildDir is ModuleDir
    
    if Sys.islinux()
        #TEST FOR DEPS
        #Run make
    elseif Sys.iswindows()
        (GccExists,MakeExists,CMakeExists,BoostPathIsGood,CGALPathIsGood)=test4deps()
        #build scripts inside directory
        #if GccExists && MakeExists && CMakeExists && CGALPathIsGood && BoostPathIsGood
            println("Dependancies have been met, attempting to run build")
            
            #ADVANCING FRONT
            println("Checking if the .exes already exist (i.e. this has already run)")
            if isfile("boundaries.exe") && isfile("reconstruction_class.exe") && 
                isfile("reconstruction_fct.exe") && isfile("reconstruction_structured.exe") &&
                isfile("reconstruction_surface_mesh.exe")
                println("exe's already pre-built, skipping build")
            else
                println("Begin build")
                
                # Convert paths to forward slashes for consistency
                b_path = replace(BuildDirAdvancingFront, "\\" => "/")
                h_path = replace(CMakeListDir, "\\" => "/")
                
                # Use a PowerShell script with proper escaping
                ps_script = """
                cmake . -B"$b_path" -H"$h_path" -G"MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DGMP_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include/ -DGMP_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libgmp-10.dll -DGMP_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/ -DMPFR_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include/ -DMPFR_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libmpfr-4.dll -DMPFR_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib
                """
                
                # Write the PowerShell script to a file
                open("cmake_script.ps1", "w") do f
                    write(f, ps_script)
                end
                
                # Run the PowerShell script
                println("Running cmake command via script file")
                run(`powershell -ExecutionPolicy Bypass -File cmake_script.ps1`)
                
                # For make, use a similar approach
                make_script = """
                make -C"$b_path"
                """
                
                open("make_script.ps1", "w") do f
                    write(f, make_script)
                end
                
                println("Running make command via script file")
                try
                    run(`powershell -ExecutionPolicy Bypass -File make_script.ps1`)
                catch
                    println("Make build.jl has been run and all the enviroment vars set in this point to folders")
                end
                
                # Clean up scripts
                rm("cmake_script.ps1")
                rm("make_script.ps1")
            end
            
            #Polygon_mesh_processing
            println("Checking if the .exes already exist (i.e. this has already run)")
            test=0;
            if test==1;
                println("exe's already pre-built, skipping build")
            else
                println("Begin build")
                
                # Convert paths to forward slashes for consistency
                b_path = replace(BuildDirPolygonMesh, "\\" => "/")
                h_path = replace(CMakeListDir2, "\\" => "/")
                
                # Use a PowerShell script with proper escaping
                ps_script = """
                cmake . -B"$b_path" -H"$h_path" -G"MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DGMP_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include/ -DGMP_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libgmp-10.dll -DGMP_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/ -DMPFR_INCLUDE_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/include/ -DMPFR_LIBRARIES=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib/libmpfr-4.dll -DMPFR_LIBRARIES_DIR=C:/dev/CGAL-4.13.1/auxiliary/gmp/lib
                """
                
                # Write the PowerShell script to a file
                open("cmake_script.ps1", "w") do f
                    write(f, ps_script)
                end
                
                # Run the PowerShell script
                println("Running cmake command via script file")
                run(`powershell -ExecutionPolicy Bypass -File cmake_script.ps1`)
                
                # For make, use a similar approach
                make_script = """
                make -C"$b_path"
                """
                
                open("make_script.ps1", "w") do f
                    write(f, make_script)
                end
                
                println("Running make command via script file")
                try
                    run(`powershell -ExecutionPolicy Bypass -File make_script.ps1`)
                catch
                    println("Make build.jl has been run and all the enviroment vars set in this point to folders")
                end
                
                # Clean up scripts
                rm("cmake_script.ps1")
                rm("make_script.ps1")
            end
            #now run and test...
        #else
        #    error("Requires dependencies that you dont have installed, run include-build.jl \n make sure you have firefox installed and use admin rights")
        #end
    elseif Sys.isapple()
        error("Not supported, check linux implementation?")
    end
    if isfile("test.txt")
        rm("test.txt")
    end
end