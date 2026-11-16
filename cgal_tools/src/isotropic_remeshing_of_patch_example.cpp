// Isotropic remeshing of a patch of a triangle mesh.
//
// Usage: isotropic_remeshing_of_patch_example <mesh.off> <target_edge_length> <TriNos.txt>
//   TriNos.txt: whitespace-separated triangle numbers to remesh, 1-based.
// Writes the whole mesh (with the patch remeshed) as OFF to stdout.
//
// Ported from examples/Polygon_mesh_processing/isotropic_remeshing_of_patch_example.cpp
// (CGAL 4.13) to CGAL >= 5.6; the remeshing parameters are unchanged.
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Surface_mesh.h>
#include <CGAL/Polygon_mesh_processing/remesh.h>

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <vector>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef CGAL::Surface_mesh<K::Point_3> Mesh;
typedef boost::graph_traits<Mesh>::face_descriptor face_descriptor;
namespace PMP = CGAL::Polygon_mesh_processing;

int main(int argc, char* argv[])
{
  if (argc < 4) {
    std::cerr << "Usage: " << argv[0]
              << " <mesh.off> <target_edge_length> <TriNos.txt>" << std::endl;
    return 2;
  }

  std::ifstream input(argv[1]);
  Mesh mesh;
  if (!input || !(input >> mesh) || !CGAL::is_triangle_mesh(mesh)) {
    std::cerr << "Not a valid input file: " << argv[1] << std::endl;
    return 1;
  }

  const double target_edge_length = std::atof(argv[2]);

  std::ifstream trifile(argv[3]);
  if (!trifile) {
    std::cerr << "ERROR: could not open triangle number file: " << argv[3] << std::endl;
    return 1;
  }
  std::vector<face_descriptor> patch;
  const std::size_t nf = num_faces(mesh);
  long id;
  while (trifile >> id) {
    if (id < 1 || static_cast<std::size_t>(id) > nf) {
      std::cerr << "ERROR: triangle number " << id << " out of range 1.." << nf << std::endl;
      return 1;
    }
    patch.push_back(face_descriptor(static_cast<Mesh::size_type>(id - 1)));
  }

  Mesh::Property_map<face_descriptor, int> selected =
      mesh.add_property_map<face_descriptor, int>("f:selected", 0).first;

  const unsigned int nb_iter = 5;
  PMP::isotropic_remeshing(
      patch,
      target_edge_length,
      mesh,
      CGAL::parameters::number_of_iterations(nb_iter)
          .face_patch_map(selected)
          .relax_constraints(true)          // not protecting border
          .collapse_constraints(true)       // not protecting border
          .number_of_relaxation_steps(15)); // more isotropic

  std::cout.setf(std::ios::fixed, std::ios::floatfield);
  std::cout.precision(13);
  std::cout << mesh << std::endl;
  return 0;
}
