#!/usr/bin/env bash
# Build the CGAL tools and pack them into a tarball for one platform.
#
# Usage: cgal_tools/build.sh <platform-triplet> <output-dir>
#   e.g. cgal_tools/build.sh x86_64-w64-mingw32 dist
#
# Needs a C++17 compiler, CMake, Boost headers, GMP and MPFR. CGAL itself is
# header-only and is downloaded here (pinned to CGAL_VERSION) unless CGAL_DIR
# is already set, so every platform builds against the same CGAL.
# Used by .github/workflows/build-cgal-tools.yml; also works locally.
set -euo pipefail

TRIPLET="$1"
OUT="$(mkdir -p "$2" && cd "$2" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
CGAL_VERSION="${CGAL_VERSION:-6.2}"
WORK="${WORK:-$OUT/work-$TRIPLET}"

rm -rf "$WORK"
mkdir -p "$WORK"

if [ -z "${CGAL_DIR:-}" ]; then
  echo "== Downloading CGAL $CGAL_VERSION (header-only)"
  curl -fsSL -o "$WORK/cgal.tar.xz" \
    "https://github.com/CGAL/cgal/releases/download/v$CGAL_VERSION/CGAL-$CGAL_VERSION-library.tar.xz"
  tar -xJf "$WORK/cgal.tar.xz" -C "$WORK"
  export CGAL_DIR="$WORK/CGAL-$CGAL_VERSION"
fi

echo "== Configuring (CGAL_DIR=$CGAL_DIR)"
cmake -S "$HERE" -B "$WORK/build" -DCMAKE_BUILD_TYPE=Release -DCGAL_DIR="$CGAL_DIR" ${CMAKE_EXTRA_ARGS:-}
echo "== Building"
cmake --build "$WORK/build" --parallel
cmake --install "$WORK/build" --prefix "$WORK/prefix"

# Linux with shared GMP/MPFR (CGAL_TOOLS_STATIC=OFF, the portable build): ship
# those libraries in lib/, where the tools' RPATH ($ORIGIN/../lib) finds them.
if [ "$(uname)" = "Linux" ]; then
  for lib in $(LD_LIBRARY_PATH="${CONDA_PREFIX:+$CONDA_PREFIX/lib}" ldd "$WORK/prefix/bin/"* \
               | awk '/lib(gmp|mpfr)[^ ]*\.so/ && $3 ~ /^\// {print $3}' | sort -u); do
    mkdir -p "$WORK/prefix/lib"
    cp -L "$lib" "$WORK/prefix/lib/"
  done
  # conda-forge's compiler adds its own lib folder to the RPATH; keep only ours.
  if [ -d "$WORK/prefix/lib" ] && command -v patchelf > /dev/null; then
    for exe in "$WORK/prefix/bin/"*; do patchelf --force-rpath --set-rpath '$ORIGIN/../lib' "$exe"; done
  fi
fi

# Strip symbols to keep the download small (macOS strip needs -x for executables).
if [ "$(uname)" = "Darwin" ]; then strip -x "$WORK/prefix/bin/"*; else strip "$WORK/prefix/bin/"*; fi

# Linux: report the newest glibc the tools need (the oldest Linux they run on).
if [ "$(uname)" = "Linux" ]; then
  echo "== Needs glibc >= $(objdump -T "$WORK/prefix/bin/"* "$WORK/prefix/lib/"* 2>/dev/null \
    | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | cut -d_ -f2)"
fi

# Record what went into the build next to the binaries.
cat > "$WORK/prefix/BUILDINFO.txt" <<EOF
platform: $TRIPLET
cgal: $CGAL_VERSION
built: $(date -u +%Y-%m-%dT%H:%M:%SZ)
source: https://github.com/Timmmdavis/BuildCGAL/tree/master/cgal_tools
EOF

echo "== Smoke test"
EXT=""; case "$TRIPLET" in *mingw*) EXT=".exe";; esac
"$WORK/prefix/bin/connected_components_example$EXT" \
  "$HERE/../examples/Polygon_mesh_processing/data/blobby_3cc.off" > "$WORK/cc.txt"
test "$(sort -u "$WORK/cc.txt" | wc -l | tr -d ' ')" = "3"
# graded_remeshing: a flat disc of 48 triangles (24 rim edges), edges 0.05 at the rim growing to 0.2 inside,
# must come back as a valid, much finer mesh
"$WORK/prefix/bin/graded_remeshing$EXT" "$HERE/test_data/disc.off" 0.2 0.05 1.3 8 0 - 0 10 > "$WORK/graded.off"
test "$(head -1 "$WORK/graded.off" | tr -d '\r')" = "OFF"
test "$(sed -n 2p "$WORK/graded.off" | awk '{print $2}')" -gt 300
echo "graded_remeshing: $(sed -n 2p "$WORK/graded.off" | awk '{print $2}') triangles"

TARBALL="$OUT/cgal_tools-$TRIPLET.tar.gz"
tar -czf "$TARBALL" -C "$WORK/prefix" .
echo "== Wrote $TARBALL"
