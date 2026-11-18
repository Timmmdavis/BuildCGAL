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

# Full OFF reader: (vertices n×3, faces as 1-based index triples)
function read_off_mesh(path)
    lines = filter(!isempty, strip.(readlines(path)))
    nv, nf = parse.(Int, split(lines[2])[1:2])
    V = reduce(vcat, [parse.(Float64, split(l)[1:3])' for l in lines[3:2+nv]])
    F = [parse.(Int, split(l))[2:4] .+ 1 for l in lines[3+nv:2+nv+nf]]
    return V, F
end

# Flat unit disc as a fan of rings (n points on the rim), written as OFF
function write_disc_off(path, n)
    P = [[0.0, 0.0]]
    for (k, r) in enumerate((0.5, 1.0)), j in 0:(k*n÷2-1)
        t = 2π * j / (k * n ÷ 2); push!(P, [r * cos(t), r * sin(t)])
    end
    m = n ÷ 2; inner = 2:(m+1); outer = (m+2):(m+1+n)
    F = [[1, inner[j], inner[mod1(j + 1, m)]] for j in 1:m]
    for j in 1:m
        a, b = inner[j], inner[mod1(j + 1, m)]
        o1, o2, o3 = outer[2j-1], outer[2j], outer[mod1(2j + 1, n)]
        append!(F, [[a, o1, o2], [a, o2, b], [b, o2, o3]])
    end
    open(path, "w") do io
        println(io, "OFF"); println(io, length(P), " ", length(F), " 0")
        foreach(p -> println(io, p[1], " ", p[2], " 0.0"), P)
        foreach(f -> println(io, "3 ", f[1] - 1, " ", f[2] - 1, " ", f[3] - 1), F)
    end
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

            # Graded remeshing of a flat unit disc: short edges at the border, long ones inside
            if isfile(joinpath(BuildCGAL.tools_dir(), Sys.iswindows() ? "graded_remeshing.exe" : "graded_remeshing"))
                disc = joinpath(dir, "disc.off")
                write_disc_off(disc, 24)
                gr = BuildCGAL.GradedRemeshingCGAL(disc, 0.2, 0.05; growth = 1.3)
                @test gr == joinpath(dir, "GradedRemeshing.off")
                V, F = read_off_mesh(gr)
                @test all(abs.(V[:, 3]) .< 1e-12)                      # still flat
                r = [hypot(V[i, 1], V[i, 2]) for i in 1:size(V, 1)]
                @test maximum(r) <= 1 + 1e-9                            # nothing outside the disc
                L(e) = hypot(V[e[1], 1] - V[e[2], 1], V[e[1], 2] - V[e[2], 2])
                # front points lie on the 24-sided polygon, so r ≥ cos(π/24) ≈ 0.991
                rim  = [L((f[i], f[mod1(i + 1, 3)])) for f in F for i in 1:3 if r[f[i]] > 0.985 && r[f[mod1(i + 1, 3)]] > 0.985]
                core = [L((f[i], f[mod1(i + 1, 3)])) for f in F for i in 1:3 if r[f[i]] < 0.5 && r[f[mod1(i + 1, 3)]] < 0.5]
                @test 0.03 < sum(rim) / length(rim) < 0.08                 # ≈ hf at the front
                @test 0.12 < sum(core) / length(core) < 0.3                # ≈ h inside
            else
                @test_skip "graded_remeshing is not in this build of the CGAL tools yet"
            end

            # Paths with spaces work
            spaced = mkpath(joinpath(dir, "a folder with spaces"))
            cp(af, joinpath(spaced, "in put.off"))
            @test isfile(BuildCGAL.ConnectedComponentsCGAL(joinpath(spaced, "in put.off")))

            # A failing tool raises an error instead of silently leaving a bad file
            @test_throws ErrorException BuildCGAL.PolygonRemeshingCGAL(joinpath(dir, "missing.off"), 0.1)
        end
    end
end
