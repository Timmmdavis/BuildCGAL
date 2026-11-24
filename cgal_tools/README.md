# Maintaining the CGAL tools

Everything you need to change, rebuild or republish the CGAL binaries that BuildCGAL uses.
Written so you can pick this up cold after a long break.

## How it fits together

```
cgal_tools/src/*.cpp          C++ programs: read a file, write the result to stdout
cgal_tools/CMakeLists.txt     lists the programs to build (the TOOLS list)
cgal_tools/build.sh           downloads CGAL, builds, smoke-tests, packs a .tar.gz
.github/workflows/build-cgal-tools.yml
                              runs build.sh on Windows, Linux, macOS when you push a
                              tag named cgal-tools-v*, then makes a GitHub release
cgal_tools/bind_artifacts.jl  writes each release file's URL and checksums into Artifacts.toml
Artifacts.toml                tells Pkg which file to download for each platform
src/BuildCGAL.jl              Julia wrappers: one function per program, via run_tool()
test/runtests.jl              runs every program on the sample data in examples/
```

When a user runs `] add BuildCGAL`, Pkg reads `Artifacts.toml`, downloads the tarball for
their platform from the GitHub release, checks its checksum, and unpacks it into
`~/.julia/artifacts/<hash>/bin`. The Julia wrappers then call the programs there.
Nothing is compiled on the user's machine.

The C++ is built against a pinned CGAL version: `CGAL_VERSION` near the top of
`build.sh` (6.2 at the time of writing). CGAL is header-only, so it's downloaded at build
time. Boost, GMP and MPFR come from each platform's package manager and are linked
statically, so every program is a single file with no DLLs.

---

## A) Build the tools on your own machine

Do this when changing the C++ or adding a program, to check it before publishing.

### 1. Install a compiler and the libraries (once per machine)

**Windows**: install [MSYS2](https://www.msys2.org/), open the **MSYS2 UCRT64** shell
(not MINGW32 and not MSYS), and run:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja \
  mingw-w64-ucrt-x86_64-boost mingw-w64-ucrt-x86_64-gmp mingw-w64-ucrt-x86_64-mpfr tar xz curl
```

This doesn't change your Windows PATH; everything stays inside `C:\msys64`.

**Linux (Debian/Ubuntu)**, for a build that only has to run on your own machine:

```bash
sudo apt-get install build-essential cmake libboost-dev libgmp-dev libmpfr-dev curl xz-utils
```

CGAL 6.2 needs Boost 1.74 or newer (Ubuntu 20.04 has 1.71). To reproduce the release build
instead, which runs on any Linux with glibc 2.17 or newer, use the conda-forge toolchain from
the workflow's "Install toolchain (Linux ...)" step: install
[micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html), then

```bash
micromamba create -p ~/cgal-env -c conda-forge --override-channels \
  gxx_linux-64 "sysroot_linux-64=2.17" cmake make libboost-devel gmp mpfr patchelf
export PATH=~/cgal-env/bin:$PATH CONDA_PREFIX=~/cgal-env CXX=~/cgal-env/bin/x86_64-conda-linux-gnu-g++
export CMAKE_EXTRA_ARGS="-DCGAL_TOOLS_STATIC=OFF -DCMAKE_PREFIX_PATH=$HOME/cgal-env"
```

That build links GMP and MPFR as shared libraries and `build.sh` copies them into `lib/`
next to `bin/`; the tools find them there on their own. `build.sh` prints the oldest glibc
the tools need (`== Needs glibc >= 2.17`).

**macOS**: install Xcode command-line tools (`xcode-select --install`) and
[Homebrew](https://brew.sh), then `brew install cmake boost gmp mpfr`.

These are the same commands the CI workflow uses. If one stops working, check the
"Install toolchain" steps in `.github/workflows/build-cgal-tools.yml`, which were last
known to work.

### 2. Build

From the repository root (on Windows, in the MSYS2 UCRT64 shell; `cd /c/Users/...` reaches your C: drive):

```bash
# Windows (MSYS2 UCRT64 shell)
CMAKE_EXTRA_ARGS="-G Ninja" bash cgal_tools/build.sh x86_64-w64-mingw32 dist
# Linux
bash cgal_tools/build.sh x86_64-linux-gnu dist
# macOS (Apple Silicon)
bash cgal_tools/build.sh aarch64-apple-darwin dist
```

The first argument is only a label used in the tarball name. The programs end up in
`dist/work-<label>/prefix/bin/` and the packed tarball in `dist/cgal_tools-<label>.tar.gz`.
`dist/` is git-ignored.

### 3. Test your build from Julia

```julia
ENV["BUILDCGAL_TOOLS_DIR"] = raw"C:\path\to\BuildCGAL\dist\work-x86_64-w64-mingw32\prefix\bin"
] dev path/to/BuildCGAL          # use your local copy of the package
] test BuildCGAL
```

`BUILDCGAL_TOOLS_DIR` overrides the downloaded tools for this Julia session only.
Unset it (`delete!(ENV, "BUILDCGAL_TOOLS_DIR")`) to go back to the release binaries.

### Adding a new CGAL program

1. **Find an example to start from.** Each CGAL package has examples in the
   [CGAL manual](https://doc.cgal.org/latest/Manual/packages.html), and the source is in
   the `examples/` folder of the
   [CGAL release](https://github.com/CGAL/cgal/releases) matching `CGAL_VERSION`.
2. **Copy it to `cgal_tools/src/<name>.cpp`** and adapt it to the same pattern as the
   existing programs:
   - inputs come from command-line arguments (file paths and numbers), with a usage
     message and `return 2` if they're missing;
   - the result goes to **stdout** (an OFF mesh or plain numbers) with
     `std::cout.precision(13)` and fixed format for coordinates;
   - errors go to **stderr** with a non-zero return code. The Julia side turns that
     into an error for the user.
3. **Add `<name>` to the `TOOLS` list** in `cgal_tools/CMakeLists.txt`.
4. **If the CGAL package needs an extra library** (for example Eigen for some
   meshing/parameterisation packages, which the CGAL docs list under "Dependencies"),
   add it in three places: the install commands in step 1 above, the matching "Install
   toolchain" steps in the workflow, and in `CMakeLists.txt`
   (e.g. `find_package(Eigen3 REQUIRED)` and link `CGAL::Eigen3_support`).
5. **Add a Julia wrapper** in `src/BuildCGAL.jl`, copying an existing one:
   ```julia
   function MyNewThingCGAL(SurfaceDir, some_parameter)
       out = joinpath(pwd(), "MyNewThing.off")
       run_tool("<name>", [SurfaceDir, some_parameter], out)
   end
   ```
   Add a docstring saying what it writes and where.
6. **Add a test** in `test/runtests.jl`, using a sample file from `examples/`.
7. Build and test locally (steps 2 and 3), then publish (part B). Users only get the new
   program after a new release, because it lives in the binaries.

### Upgrading CGAL

Change `CGAL_VERSION` in `build.sh`, build and test locally, then publish (part B).
Check the [CGAL changelog](https://github.com/CGAL/cgal/releases) for API removals:
going from 4.13 to 6.x needed `CGAL::parameters::` instead of
`PMP::parameters::` and `std::array` instead of `CGAL::cpp11::array`. Remeshing results
can change slightly between CGAL versions, so say so in the release notes.

---

## B) Publish new binaries

Do this after any change to `cgal_tools/` (C++, CMake, build.sh or CGAL version).
Changes to the Julia code alone don't need new binaries.

### Checklist

1. **Commit and push your source changes to `master`**:
   ```bash
   git add cgal_tools src test
   git commit -m "Add mesh_smoothing tool (CGAL tangential relaxation)"
   git push origin master
   ```
2. **Pick the next tag.** Look at the existing ones
   (`git tag -l "cgal-tools-v*"` or the Releases page) and add one: after
   `cgal-tools-v1` comes `cgal-tools-v2`. **Never reuse or move a tag once users may have
   installed from it**: `Artifacts.toml` pins exact checksums, so anyone on the old
   commit gets a "Hash Mismatch" error.
3. **Push the tag. This starts the build:**
   ```bash
   git tag cgal-tools-v2
   git push origin cgal-tools-v2
   ```
4. **Watch the run** on the repository's **Actions** tab ("build-cgal-tools"). It takes
   about 5 minutes. When it's done, the **Releases** page should show `cgal-tools-v2` with
   three `.tar.gz` files: `x86_64-w64-mingw32`, `x86_64-linux-gnu` and
   `aarch64-apple-darwin`.
5. **Record the new files in `Artifacts.toml`** (any machine with Julia, from the repo root):
   ```bash
   julia cgal_tools/bind_artifacts.jl cgal-tools-v2
   ```
   It prints one `bound <platform> tree=... sha256=...` line per platform. A
   "Skipping ..." warning means that platform's file is missing from the release; see
   troubleshooting below.
6. **Bump the package version** in `Project.toml` (e.g. `0.2.0` → `0.3.0` if you added a
   program or changed CGAL, `0.2.1` for a C++ bug fix).
7. **Commit and push.** Do this promptly: until it's pushed, new installs still get the
   previous binaries.
   ```bash
   git add Artifacts.toml Project.toml
   git commit -m "Bind cgal-tools-v2 release binaries (Windows, Linux, macOS arm64)"
   git push origin master
   ```
8. **Check a clean install** in a throwaway environment:
   ```julia
   import Pkg; Pkg.activate(temp = true)
   Pkg.add(url = "https://github.com/Timmmdavis/BuildCGAL.git")
   Pkg.test("BuildCGAL")
   ```

### What to write

- **Source commit** (step 1): what changed and why, e.g.
  `Add mesh_smoothing tool (CGAL tangential relaxation)` or
  `Upgrade CGAL 6.2 -> 6.4; port remeshing to new named parameters`.
- **Binding commit** (step 7):
  `Bind cgal-tools-v2 release binaries (Windows, Linux, macOS arm64)`. List only the
  platforms that were actually bound.
- **Release notes**: the workflow fills in a standard description. On the Releases page,
  click **Edit** on the new release and add a short list:
  ```
  CGAL 6.4 (was 6.2)
  - New: mesh_smoothing (BuildCGAL.MeshSmoothingCGAL)
  - Remeshing output may differ slightly from cgal-tools-v1 because of the CGAL upgrade
  Built from commit <short hash>.
  ```
  Each tarball also has a `BUILDINFO.txt` recording its platform, CGAL version and build date.

### Troubleshooting

- **A job fails with "The configuration '...' is not supported", or is cancelled within
  seconds.** GitHub has retired that runner image (this happened to `macos-14`). Change
  the `os:` value in the workflow's `matrix` to a current image (`windows-latest`,
  `ubuntu-latest`, `macos-latest`), push to `master`, and push a **new** tag. The release
  step still publishes the platforms that did build, so you can bind those and fix the
  other one later.
- **Linux: which Linux the tools run on** is set by the conda-forge sysroot
  (`sysroot_linux-64=2.17` in the workflow), not by the runner, so `ubuntu-latest` is fine.
  Programs built against a newer glibc don't run on older Linux (users see
  ``version `GLIBC_2.34' not found``); the build log's `== Needs glibc >= ...` line shows
  what a build needs. Keep it at 2.17 unless conda-forge drops it, and say so in the release
  notes if it goes up.
- **The build step fails.** Open the job log on the Actions tab. Package-name changes in
  MSYS2/apt/brew and CGAL API changes are the usual causes. Reproduce locally with part A.
- **Users report "Hash Mismatch" on `cgal_tools`.** Their copy of BuildCGAL lists
  different checksums from the files on the release. Usually they installed between
  pushing a tag and pushing the binding commit, and `] up BuildCGAL` fixes it. If it
  persists, a release file was replaced after binding: re-run `bind_artifacts.jl` for that
  tag and push.
- **"BuildCGAL has no prebuilt CGAL tools for this platform"** (e.g. Intel Mac, Linux on
  ARM). Either point that user at part A and `BUILDCGAL_TOOLS_DIR`, or add the platform:
  a new `matrix` entry in the workflow (runner + label) and a matching line in
  `PLATFORMS` in `bind_artifacts.jl`, then publish a new tag.

### Trying the workflow without making a release

On the Actions tab, select **build-cgal-tools** → **Run workflow**. This builds all
platforms and keeps the tarballs as downloadable workflow artifacts (bottom of the run
page) without creating a release or touching `Artifacts.toml`.
