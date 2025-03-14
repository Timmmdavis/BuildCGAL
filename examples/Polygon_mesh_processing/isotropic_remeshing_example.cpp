#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Surface_mesh.h>

#include <CGAL/Polygon_mesh_processing/remesh.h>
#include <CGAL/Polygon_mesh_processing/border.h>

#include <boost/function_output_iterator.hpp>
#include <fstream>
#include <vector>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef CGAL::Surface_mesh<K::Point_3> Mesh;

typedef boost::graph_traits<Mesh>::halfedge_descriptor halfedge_descriptor;
typedef boost::graph_traits<Mesh>::edge_descriptor     edge_descriptor;

namespace PMP = CGAL::Polygon_mesh_processing;

struct halfedge2edge
{
  halfedge2edge(const Mesh& m, std::vector<edge_descriptor>& edges)
    : m_mesh(m), m_edges(edges)
  {}
  void operator()(const halfedge_descriptor& h) const
  {
    m_edges.push_back(edge(h, m_mesh));
  }
  const Mesh& m_mesh;
  std::vector<edge_descriptor>& m_edges;
};

int main(int argc, char* argv[])
{
  const char* filename = (argc > 1) ? argv[1] : "data/pig.off";
  std::ifstream input(filename);

  Mesh mesh;
  if (!input || !(input >> mesh) || !CGAL::is_triangle_mesh(mesh)) {
    std::cerr << "Not a valid input file." << std::endl;
    return 1;
  }


  if (argc > 2)
    {
      std::stringstream Stream;
      double target_edge_length = 0.0;
      Stream << argv[2];
      Stream >> target_edge_length;
    //double target_edge_length = 0.08;
  unsigned int nb_iter = 5;

  //std::cout << "target_edge_length: " << target_edge_length << std::endl;

  /*
  //std::cout << "Split border...";
    std::vector<edge_descriptor> border;
    PMP::border_halfedges(faces(mesh),
      mesh,
      boost::make_function_output_iterator(halfedge2edge(mesh, border)));
    PMP::split_long_edges(border, target_edge_length, mesh);
*/

  //std::cout << "Remesh...";
  PMP::isotropic_remeshing(
      faces(mesh),
      target_edge_length,
      mesh,
      PMP::parameters::number_of_iterations(nb_iter)
      //https://doc.cgal.org/latest/Polygon_mesh_processing/group__pmp__namedparameters.html
      //.protect_constraints(true)  //i.e. protect border, here
      .relax_constraints(true)      // not protecting border
      .collapse_constraints(true)   // not protecting border
      .number_of_relaxation_steps(15)//more isotropic
      );

  //Output precision to match Julias. 
  std::cout.setf( std::ios::fixed, std:: ios::floatfield ); // floatfield set to fixed
  std::cout.precision(13);
  std::cout << mesh  << std::endl;

    }
  return 0;
}