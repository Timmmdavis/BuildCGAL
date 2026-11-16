# BuildCGAL

Julia functions for meshing with [CGAL](https://www.cgal.org/): advancing-front surface
reconstruction, isotropic remeshing (whole mesh or a patch) and connected components.
Used by [CutAndDisplaceJulia](https://github.com/Timmmdavis/CutAndDisplaceJulia).

## Install

```julia
] add https://github.com/Timmmdavis/BuildCGAL.git
```

That's all. The CGAL tools come prebuilt: Pkg downloads the right ones for your machine
(with a progress bar) into your Julia depot. You don't need a compiler, admin rights,
7-Zip, Boost, MSYS2 or any PATH changes.

Prebuilt for: Windows x86_64, Linux x86_64 (glibc), macOS Apple Silicon.

Check it works:

```julia
] test BuildCGAL
```

## Use

Each function writes its result to a file in the current directory and returns that path.

```julia
using BuildCGAL
off = BuildCGAL.AdvancingFrontCGAL("points.xyz")                 # -> AdvancingFrontMeshed.off
off = BuildCGAL.PolygonRemeshingCGAL("mesh.off", 0.1)             # -> IsotropicRemeshing.off
off = BuildCGAL.PolygonRemeshingPatchCGAL("mesh.off", "TriNos.txt", 0.05)  # -> IsotropicRemeshingPatch.off
txt = BuildCGAL.ConnectedComponentsCGAL("mesh.off")               # -> ConnectedComponents.txt
```

`TriNos.txt` lists the triangles to remesh, one 1-based number per line. If a tool fails,
the function throws an error that includes CGAL's message.

## Using your own build of the tools

The C++ source is in [`cgal_tools/`](cgal_tools). To build it yourself (for an unsupported
platform, or to change the C++), you need a C++17 compiler, CMake, Boost, GMP and MPFR:

```bash
bash cgal_tools/build.sh <platform-name> dist
```

Then point BuildCGAL at the executables for the current Julia session:

```julia
ENV["BUILDCGAL_TOOLS_DIR"] = "path/to/folder/with/the/executables"
BuildCGAL.tools_dir()   # shows which folder is in use
```

## Maintaining: adding tools, upgrading CGAL, publishing binaries

See the step-by-step guide in [`cgal_tools/README.md`](cgal_tools/README.md). In short:
change the C++ in `cgal_tools/`, push a new tag `cgal-tools-vN` (GitHub Actions builds every
platform and makes a release), run `julia cgal_tools/bind_artifacts.jl cgal-tools-vN`, then
commit and push `Artifacts.toml`.

## Upgrading from the old installer

Earlier versions compiled CGAL 4.13.1 on your machine and added Make, MinGW, Boost and
CGAL folders to your user PATH. None of that is needed now. You can remove those PATH entries
(`C:\Program Files (x86)\GnuWin32\bin`, `...\mingw-w64\...\mingw32\bin`, `C:\boost_1_70_0`,
`C:\dev\CGAL-4.13.1`, ...) if nothing else uses them. `BuildCGAL.Compile_CGAL_Meshing_Functions()`
still exists so old scripts run, but it does nothing now.

The tools are now built against CGAL 6.2 (previously 4.13.1), so remeshed meshes can differ
slightly in their exact vertex positions from ones made with the old build.

## Mesh conventions

> Triangles = Triangles is a list where each row contains 3 row index locations in array 'Points' which contains the XYZ location of each corner of the triangle
> Points = Cols 2 3 and 4 are the xyz locations of one the corner points of a triangle.
