"""
    BuildCGAL

Julia wrappers around four small CGAL command-line tools used for meshing:
advancing-front surface reconstruction, isotropic remeshing (whole mesh or a
patch) and connected components.

The tools come prebuilt. `] add BuildCGAL` downloads the right binaries for
your machine as a Julia artifact, so there is nothing to compile and no PATH
or other system settings to change. Each wrapper writes its result to a file in
the current directory and returns that file's path.

To use binaries you built yourself (see `cgal_tools/` in the repository), set
the environment variable `BUILDCGAL_TOOLS_DIR` to the folder that contains them.
`BuildCGAL.tools_dir()` shows which folder is in use.
"""
module BuildCGAL

using Artifacts

const ARTIFACTS_TOML = joinpath(@__DIR__, "..", "Artifacts.toml")
const TOOLS_ENV = "BUILDCGAL_TOOLS_DIR"

"""
    tools_dir() -> String

Folder holding the CGAL tool executables: `ENV["BUILDCGAL_TOOLS_DIR"]` if set,
otherwise the prebuilt artifact for this platform.
"""
function tools_dir()
    override = get(ENV, TOOLS_ENV, "")
    if !isempty(override)
        isdir(override) || error("$TOOLS_ENV is set to \"$override\", which is not a folder.")
        return override
    end
    hash = artifact_hash("cgal_tools", ARTIFACTS_TOML)
    if hash === nothing
        platform = Base.BinaryPlatforms.triplet(Base.BinaryPlatforms.HostPlatform())
        error("""
            BuildCGAL has no prebuilt CGAL tools for this platform ($platform).
            Build them from the `cgal_tools` folder of the BuildCGAL repository and set
            ENV["$TOOLS_ENV"] to the folder containing the executables.""")
    end
    if !artifact_exists(hash)
        error("""
            The prebuilt CGAL tools have not been downloaded yet.
            Run `import Pkg; Pkg.instantiate()` (or re-run `] add BuildCGAL`) to fetch them.""")
    end
    return joinpath(artifact_path(hash), "bin")
end

"""
    tool(name) -> String

Full path of the CGAL tool `name` (without `.exe`), checking that it exists.
"""
function tool(name::AbstractString)
    exe = joinpath(tools_dir(), Sys.iswindows() ? "$name.exe" : name)
    isfile(exe) || error("CGAL tool not found: $exe")
    return exe
end

# Run a tool, sending its stdout to `outfile`. The tool's own messages (stderr)
# go straight to the REPL. Throws if the tool fails.
function run_tool(name, args, outfile)
    exe = tool(name)
    cmd = `$exe $args`
    @debug "Running CGAL tool" cmd outfile
    proc = run(pipeline(ignorestatus(cmd); stdout = outfile, stderr = stderr))
    success(proc) ||
        error("CGAL tool `$name` failed (exit code $(proc.exitcode)). Command: $cmd")
    return outfile
end

"""
    AdvancingFrontCGAL(PointsDir; radius_ratio_bound=5, beta=0.52) -> String

Reconstruct a triangulated surface from the points in the `.xyz` file
`PointsDir`. Writes `AdvancingFrontMeshed.off` in the current directory and
returns its path.
"""
function AdvancingFrontCGAL(PointsDir; radius_ratio_bound = 5, beta = 0.52)
    out = joinpath(pwd(), "AdvancingFrontMeshed.off")
    run_tool("reconstruction_surface_mesh", [PointsDir, radius_ratio_bound, beta], out)
end

"""
    PolygonRemeshingCGAL(SurfaceDir, target_edge_length) -> String

Isotropically remesh the triangle mesh in the `.off` file `SurfaceDir`.
Writes `IsotropicRemeshing.off` in the current directory and returns its path.
"""
function PolygonRemeshingCGAL(SurfaceDir, target_edge_length)
    out = joinpath(pwd(), "IsotropicRemeshing.off")
    run_tool("isotropic_remeshing_example", [SurfaceDir, target_edge_length], out)
end

"""
    PolygonRemeshingPatchCGAL(SurfaceDir, TriNumbersTxtDir, target_edge_length) -> String

Isotropically remesh only the triangles listed (1-based, one per line) in the
text file `TriNumbersTxtDir`. Writes `IsotropicRemeshingPatch.off` in the
current directory and returns its path.
"""
function PolygonRemeshingPatchCGAL(SurfaceDir, TriNumbersTxtDir, target_edge_length)
    out = joinpath(pwd(), "IsotropicRemeshingPatch.off")
    run_tool("isotropic_remeshing_of_patch_example",
             [SurfaceDir, target_edge_length, TriNumbersTxtDir], out)
end

"""
    ConnectedComponentsCGAL(SurfaceDir) -> String

Label the face-connected components of the mesh in `SurfaceDir`. Writes
`ConnectedComponents.txt` (one 0-based component id per triangle) in the
current directory and returns its path.
"""
function ConnectedComponentsCGAL(SurfaceDir)
    out = joinpath(pwd(), "ConnectedComponents.txt")
    run_tool("connected_components_example", [SurfaceDir], out)
end

"""
    Compile_CGAL_Meshing_Functions()

No longer needed: the CGAL tools are downloaded prebuilt when BuildCGAL is
installed. Kept so older scripts still run; it just reports where the tools are.
"""
function Compile_CGAL_Meshing_Functions()
    dir = tools_dir()
    @info "BuildCGAL no longer compiles anything; using the prebuilt CGAL tools in $dir"
    return dir
end

end # module
