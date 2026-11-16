# Self-contained checks that each CGAL tool runs and gives sensible output.
# Needs nothing beyond BuildCGAL itself and the sample data in examples/.
using Test
using BuildCGAL

const DATA = joinpath(dirname(@__DIR__), "examples")

# Minimal OFF reader: (number of vertices, number of faces, largest vertex index used).
function read_off(path)
    lines = filter(!isempty, strip.(readlines(path)))
    @test lines[1] == "OFF"
    nv, nf = parse.(Int, split(lines[2])[1:2])
    faces = [parse.(Int, split(l)) for l in lines[3+nv:2+nv+nf]]
    @test all(f -> f[1] == 3 && length(f) == 4, faces)   # all triangles
    return nv, nf, maximum(maximum(f[2:4]) for f in faces)
end

@testset "BuildCGAL" begin
    @test isdir(BuildCGAL.tools_dir())

    mktempdir() do dir
        cd(dir) do
            # Advancing front: point cloud -> surface
            af = BuildCGAL.AdvancingFrontCGAL(joinpath(DATA, "Advancing_front_surface_reconstruction", "data", "half.xyz"))
            @test af == joinpath(dir, "AdvancingFrontMeshed.off")
            nv, nf, maxidx = read_off(af)
            @test nv > 100 && nf > 100 && maxidx < nv

            # Whole-mesh remeshing at a finer edge length gives more triangles
            rm = BuildCGAL.PolygonRemeshingCGAL(af, 0.05)
            nv2, nf2, maxidx2 = read_off(rm)
            @test nf2 > nf && maxidx2 < nv2

            # Patch remeshing of the first 20 triangles only
            tris = joinpath(dir, "TriNos.txt")
            write(tris, join(1:20, "\n"))
            rmp = BuildCGAL.PolygonRemeshingPatchCGAL(rm, tris, 0.02)
            _, nf3, _ = read_off(rmp)
            @test nf3 > nf2

            # Connected components: the sample mesh has three separate pieces
            cc = BuildCGAL.ConnectedComponentsCGAL(joinpath(DATA, "Polygon_mesh_processing", "data", "blobby_3cc.off"))
            ids = parse.(Int, filter(!isempty, readlines(cc)))
            @test sort(unique(ids)) == [0, 1, 2]

            # Paths with spaces work
            spaced = mkpath(joinpath(dir, "a folder with spaces"))
            cp(af, joinpath(spaced, "in put.off"))
            @test isfile(BuildCGAL.ConnectedComponentsCGAL(joinpath(spaced, "in put.off")))

            # A failing tool raises an error instead of silently leaving a bad file
            @test_throws ErrorException BuildCGAL.PolygonRemeshingCGAL(joinpath(dir, "missing.off"), 0.1)
        end
    end
end
