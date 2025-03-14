#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Surface_mesh.h>
#include <CGAL/Polygon_mesh_processing/connected_components.h>
#include <boost/function_output_iterator.hpp>
#include <boost/property_map/property_map.hpp>
#include <boost/foreach.hpp>
#include <iostream>
#include <fstream>
#include <map>
typedef CGAL::Exact_predicates_inexact_constructions_kernel Kernel;
typedef Kernel::Point_3                                     Point;
typedef Kernel::Compare_dihedral_angle_3                    Compare_dihedral_angle_3;
typedef CGAL::Surface_mesh<Point>                           Mesh;
namespace PMP = CGAL::Polygon_mesh_processing;
template <typename G>
struct Constraint : public boost::put_get_helper<bool,Constraint<G> >
{
  typedef typename boost::graph_traits<G>::edge_descriptor edge_descriptor;
  typedef boost::readable_property_map_tag      category;
  typedef bool                                  value_type;
  typedef bool                                  reference;
  typedef edge_descriptor                       key_type;
  Constraint()
    :g_(NULL)
  {}
  Constraint(G& g, double bound) 
    : g_(&g), bound_(bound)
  {}
  bool operator[](edge_descriptor e) const
  {
    const G& g = *g_;
    return compare_(g.point(source(e, g)),
                    g.point(target(e, g)),
                    g.point(target(next(halfedge(e, g), g), g)),
                    g.point(target(next(opposite(halfedge(e, g), g), g), g)),
                   bound_) == CGAL::SMALLER;
  }
  const G* g_;
  Compare_dihedral_angle_3 compare_;
  double bound_;
};
template <typename PM>
struct Put_true
{
  Put_true(const PM pm)
    :pm(pm)
  {}
  template <typename T>
  void operator()(const T& t)
  {
    put(pm, t, true);
  }
  PM pm;
};
int main(int argc, char* argv[])
{
  const char* filename = (argc > 1) ? argv[1] : "data/blobby_3cc.off";
  std::ifstream input(filename);
  Mesh mesh;
  if (!input || !(input >> mesh) || mesh.is_empty()) {
    std::cerr << "Not a valid off file." << std::endl;
    return 1;
  }


  typedef boost::graph_traits<Mesh>::face_descriptor face_descriptor;
  const double bound = std::cos(2 * CGAL_PI); //no filtering of components based on the diherdral angle between tris!
  std::vector<face_descriptor> cc;
  face_descriptor fd = *faces(mesh).first;
  PMP::connected_component(fd,
      mesh,
      std::back_inserter(cc));

  
  // Instead of writing the faces into a container, you can set a face property to true
  typedef Mesh::Property_map<face_descriptor, bool> F_select_map;
  F_select_map fselect_map =
    mesh.add_property_map<face_descriptor, bool>("f:select", false).first;

  Mesh::Property_map<face_descriptor, std::size_t> fccmap =
    mesh.add_property_map<face_descriptor, std::size_t>("f:CC").first;
  std::size_t num = PMP::connected_components(mesh,
      fccmap,
      PMP::parameters::edge_is_constrained_map(Constraint<Mesh>(mesh, bound)));
  std::cerr << "- The graph has " << num << " connected components (face connectivity)" << std::endl;
  typedef std::map<std::size_t/*index of CC*/, unsigned int/*nb*/> Components_size;
  Components_size nb_per_cc;
  BOOST_FOREACH(face_descriptor f , faces(mesh)){
    nb_per_cc[ fccmap[f] ]++;
    //prints each component as new no - 3 parts flag would contain = 0 1 2 
    std::cout << fccmap[f] << std::endl; 
  }

  //if you wanted the sizes:  

  //BOOST_FOREACH(const Components_size::value_type& cc, nb_per_cc){
  //  std::cout << "\t CC #" << cc.first
  //            << " is made of " << cc.second << " faces" << std::endl;
  //}




  return 0;
}