# Write Artifacts.toml entries for the prebuilt CGAL tools.
#
# Usage (from the repository root):
#   julia cgal_tools/bind_artifacts.jl <release-tag> [local-dir]
#
# For each supported platform this takes cgal_tools-<triplet>.tar.gz, either
# from [local-dir] or downloaded from the GitHub release <release-tag>, and
# records its content hash and download URL in Artifacts.toml. Pkg then fetches
# the right tarball for each user's machine during `] add BuildCGAL`.
using Pkg, Pkg.Artifacts, Base.BinaryPlatforms, SHA, Downloads, Tar

const REPO = "Timmmdavis/BuildCGAL"
const NAME = "cgal_tools"
const PLATFORMS = [
    "x86_64-w64-mingw32"   => Platform("x86_64", "windows"),
    "x86_64-linux-gnu"     => Platform("x86_64", "linux"; libc = "glibc"),
    "aarch64-apple-darwin" => Platform("aarch64", "macos"),
]

tag = length(ARGS) >= 1 ? ARGS[1] : error("usage: julia cgal_tools/bind_artifacts.jl <release-tag> [local-dir]")
localdir = length(ARGS) >= 2 ? ARGS[2] : nothing
toml = joinpath(@__DIR__, "..", "Artifacts.toml")

for (triplet, platform) in PLATFORMS
    file = "$NAME-$triplet.tar.gz"
    url = "https://github.com/$REPO/releases/download/$tag/$file"
    path = localdir === nothing ? nothing : joinpath(localdir, file)
    if path === nothing || !isfile(path)
        path = joinpath(mktempdir(), file)
        try
            Downloads.download(url, path)
        catch e
            @warn "Skipping $triplet: could not get $file" exception = e
            continue
        end
    end
    sha256 = bytes2hex(open(SHA.sha256, path))
    # Tree hash of the tarball contents, computed from the tar stream itself so
    # it is the same whichever OS runs this script.
    treehash = open(`$(Pkg.PlatformEngines.exe7z()) x $path -so`) do io
        Base.SHA1(Tar.tree_hash(io))
    end
    # If this is the current machine's platform, unpack it into the local depot
    # too, so BuildCGAL works here before anything has been published.
    if platforms_match(platform, HostPlatform()) && !artifact_exists(treehash)
        got = create_artifact(dir -> Pkg.PlatformEngines.unpack(path, dir))
        got == treehash || @warn "Local unpack of $file hashed to $got, expected $treehash"
    end
    bind_artifact!(toml, NAME, treehash; platform, download_info = [(url, sha256)], force = true)
    println("bound $triplet  tree=$treehash  sha256=$sha256")
end
