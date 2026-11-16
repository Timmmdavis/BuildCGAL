// Isotropic remeshing of a whole triangle mesh.
//
// Usage: isotropic_remeshing_example <mesh.off> <target_edge_length>
// Writes the remeshed surface as OFF to stdout.
//
// Ported from examples/Polygon_mesh_processing/isotropic_remeshing_example.cpp
// (CGAL 4.13) to CGAL >= 5.6; the remeshing parameters are unchanged.
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Surface_mesh.h>
#include <CGAL/Polygon_mesh_processing/remesh.h>

#include <cstdlib>
#include <fstream>
#include <iostream>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef CGAL::Surface_mesh<K::Point_3> Mesh;
namespace PMP = CGAL::Polygon_mesh_processing;

int main(int argc, char* argv[])
{
  if (argc < 3) {
    std::cerr << "Usage: " << argv[0] << " <mesh.off> <target_edge_length>" << std::endl;
    return 2;
  }

  std::ifstream input(argv[1]);
  Mesh mesh;
  if (!input || !(input >> mesh) || !CGAL::is_triangle_mesh(mesh)) {
    std::cerr << "Not a valid input file: " << argv[1] << std::endl;
    return 1;
  }

  const double target_edge_length = std::atof(argv[2]);
  const unsigned int nb_iter = 5;

  PMP::isotropic_remeshing(
      faces(mesh),
      target_edge_length,
      mesh,
      CGAL::parameters::number_of_iterations(nb_iter)
          .relax_constraints(true)          // not protecting border
          .collapse_constraints(true)       // not protecting border
          .number_of_relaxation_steps(15)); // more isotropic

  // Output precision to match Julia's reader.
  std::cout.setf(std::ios::fixed, std::ios::floatfield);
  std::cout.precision(13);
  std::cout << mesh << std::endl;
  return 0;
}
