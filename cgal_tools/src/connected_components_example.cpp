// Face-connected components of a triangle mesh.
//
// Usage: connected_components_example <mesh.off>
// Writes one line per face to stdout: the 0-based component id of that face.
//
// Ported from examples/Polygon_mesh_processing/connected_components_example.cpp
// (CGAL 4.13). The original passed an edge_is_constrained_map that compared
// each dihedral angle against cos(2*pi) = 1, i.e. an angle of 0, so no edge was
// ever constrained. It is dropped here; the result is identical.
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Surface_mesh.h>
#include <CGAL/Polygon_mesh_processing/connected_components.h>

#include <fstream>
#include <iostream>

typedef CGAL::Exact_predicates_inexact_constructions_kernel Kernel;
typedef CGAL::Surface_mesh<Kernel::Point_3> Mesh;
typedef boost::graph_traits<Mesh>::face_descriptor face_descriptor;
namespace PMP = CGAL::Polygon_mesh_processing;

int main(int argc, char* argv[])
{
  if (argc < 2) {
    std::cerr << "Usage: " << argv[0] << " <mesh.off>" << std::endl;
    return 2;
  }

  std::ifstream input(argv[1]);
  Mesh mesh;
  if (!input || !(input >> mesh) || mesh.is_empty()) {
    std::cerr << "Not a valid off file: " << argv[1] << std::endl;
    return 1;
  }

  Mesh::Property_map<face_descriptor, std::size_t> fccmap =
      mesh.add_property_map<face_descriptor, std::size_t>("f:CC").first;
  const std::size_t num = PMP::connected_components(mesh, fccmap);
  std::cerr << "- The graph has " << num
            << " connected components (face connectivity)" << std::endl;

  for (face_descriptor f : faces(mesh))
    std::cout << fccmap[f] << '\n';
  return 0;
}
