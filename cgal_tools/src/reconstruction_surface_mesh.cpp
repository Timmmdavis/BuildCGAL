// Advancing-front surface reconstruction from a point cloud.
//
// Usage: reconstruction_surface_mesh <points.xyz> [radius_ratio_bound=5] [beta=0.52]
// Writes the reconstructed surface as OFF to stdout.
//
// Ported from examples/Advancing_front_surface_reconstruction/reconstruction_surface_mesh.cpp
// (CGAL 4.13) to CGAL >= 5.6. The original re-used one stringstream for both
// numbers, so beta was always left at 0.52; BuildCGAL always passes 0.52, so
// parsing each argument separately does not change any result.
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Advancing_front_surface_reconstruction.h>
#include <CGAL/Surface_mesh.h>

#include <algorithm>
#include <array>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iterator>
#include <vector>

typedef std::array<std::size_t, 3> Facet;
typedef CGAL::Exact_predicates_inexact_constructions_kernel Kernel;
typedef Kernel::Point_3 Point_3;
typedef CGAL::Surface_mesh<Point_3> Mesh;

struct Construct {
  Mesh& mesh;

  template <typename PointIterator>
  Construct(Mesh& mesh, PointIterator b, PointIterator e) : mesh(mesh)
  {
    for (; b != e; ++b) {
      boost::graph_traits<Mesh>::vertex_descriptor v = add_vertex(mesh);
      mesh.point(v) = *b;
    }
  }

  Construct& operator=(const Facet f)
  {
    typedef boost::graph_traits<Mesh>::vertex_descriptor vertex_descriptor;
    typedef boost::graph_traits<Mesh>::vertices_size_type size_type;
    mesh.add_face(vertex_descriptor(static_cast<size_type>(f[0])),
                  vertex_descriptor(static_cast<size_type>(f[1])),
                  vertex_descriptor(static_cast<size_type>(f[2])));
    return *this;
  }

  Construct& operator*() { return *this; }
  Construct& operator++() { return *this; }
  Construct operator++(int) { return *this; }
};

int main(int argc, char* argv[])
{
  if (argc < 2) {
    std::cerr << "Usage: " << argv[0]
              << " <points.xyz> [radius_ratio_bound=5] [beta=0.52]" << std::endl;
    return 2;
  }

  std::ifstream in(argv[1]);
  if (!in) {
    std::cerr << "Could not open point file: " << argv[1] << std::endl;
    return 1;
  }
  const double radius_ratio_bound = (argc > 2) ? std::atof(argv[2]) : 5.0;
  const double beta = (argc > 3) ? std::atof(argv[3]) : 0.52;

  std::vector<Point_3> points;
  std::copy(std::istream_iterator<Point_3>(in),
            std::istream_iterator<Point_3>(),
            std::back_inserter(points));

  Mesh m;
  Construct construct(m, points.begin(), points.end());
  CGAL::advancing_front_surface_reconstruction(points.begin(), points.end(),
                                               construct, radius_ratio_bound, beta);

  std::cout.setf(std::ios::fixed, std::ios::floatfield);
  std::cout.precision(13);
  std::cout << m << std::endl;
  return 0;
}
