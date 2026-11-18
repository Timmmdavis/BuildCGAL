# The small CGAL command-line tools that BuildCGAL calls.
#
# These are built once per platform by .github/workflows/build-cgal-tools.yml,
# packed into a tarball and attached to a GitHub release. Julia users never
# compile anything: Pkg downloads the matching tarball as an artifact.
#
# Local build (any platform with CGAL >= 5.6, Boost, GMP and MPFR available):
#   cmake -S cgal_tools -B build -DCMAKE_BUILD_TYPE=Release
#   cmake --build build
#   cmake --install build --prefix <outdir>
cmake_minimum_required(VERSION 3.16)
project(BuildCGAL_tools CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# Link the C++ runtime, GMP and MPFR statically where possible so each tool is
# a single self-contained executable (no DLLs or .so files to ship).
option(CGAL_TOOLS_STATIC "Link the tools statically" ON)
if(CGAL_TOOLS_STATIC)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
  if(WIN32)
    add_link_options(-static)
  elseif(NOT APPLE)
    add_link_options(-static-libstdc++ -static-libgcc)
  endif()
endif()

find_package(CGAL REQUIRED)

set(TOOLS
  reconstruction_surface_mesh
  isotropic_remeshing_example
  graded_remeshing
  isotropic_remeshing_of_patch_example
  connected_components_example
)

foreach(tool ${TOOLS})
  add_executable(${tool} src/${tool}.cpp)
  target_link_libraries(${tool} PRIVATE CGAL::CGAL)
  install(TARGETS ${tool} RUNTIME DESTINATION bin)
endforeach()
