home/tim/Downloads/CGAL-4.14

#Installed CGAL using 
sudo apt-get install libcgal-dev
#Also the demos
#extracted files in 
tar -xvf /usr/share/doc/libgcal/examples -C /MYHOMEDIR
#In this folder (or a sub folder i.e. ADVANCINGFRONT) I then call
cmake .
make
#then you end up with a load of files with the same names as the X.cpp. Just call ./X to run for example capturing the terminal output in a file:

In Linux: paste from : 
/downloads/CGAL-4.13.1/CGAL-4.13.1/examples/Advancing_front_surface_reconstruction
into: 
/home/username/.julia/packages/BuildCGAL/xxxxx/examples/BuildDirAdvFront/
check there are no #CMakeLists.txt files hanging around
then call in terminal 
cmake .
make
Do the same for 
/downloads/CGAL-4.13.1/CGAL-4.13.1/examples/Polygon_mesh_processing
then you should be able to use without the extra stuff. 




######################################################################
Advancing Front: - after calling make (inside the its examples folder)
https://doc.cgal.org/latest/Advancing_front_surface_reconstruction/index.html#title7

#For example in: /Desktop/examples/Advancing_front_surface_reconstruction$ 
./reconstruction_surface_mesh data/YourFileName.xyz > output.off #OFF file https://en.wikipedia.org/wiki/OFF_(file_format)

windows:
./isotropic_remeshing_example "C:\Users\timmm\.julia\packages\BuildCGAL\E7q8G\examples\Polygon_mesh_processing\data\pig.off" 0.1  | out-file -Encoding ascii "out.off"

#This is based on the input half.xyz text file in /Advancing_front_surface_reconstruction/data
#You can always change the name of the file in the reconstruction_surface_mesh.cpp file before remaking
#If you want the boundaries call:
./boundaries > output.xyz #MAKE SURE THE OUTPUT FILE IS DELETED WHEN LOADED 
#Giving you a point list of the boundaries (I am guessing ordered) which may help with cleaning the mesh later. 
#You may need post processing like Ewan Brock implemented removing slither tris/ones of a certain area. 

######################################################################
Polygon Mesh Processing / isotropic remeshing : - after calling make (inside the its examples folder)
https://doc.cgal.org/latest/Polygon_mesh_processing/group__PMP__meshing__grp.html#gad3d03890515ae8103bd32a30a3486412

#In /home/tim/Desktop/examples/Polygon_mesh_processing
#Change line in Polygon_mesh_processing/isotropic_remeshing_example.cpp:   

std::cout << "Remeshing done." << std::endl;
#to
std::cout << mesh  << std::endl;
#and remove all other lines starting with: std::cout (just use // infront of these lines) note lines 57-58 both need to be commented. 
#These two paramters control the algorithm: 
#  double target_edge_length = 0.04; #THIS NEEDS TO BE CAREFULLY SELECTED
#  unsigned int nb_iter = 3;
#To pass another surface (see input params)
./isotropic_remeshing_example "data/eight.off" >> out.off
#

#then REMAKE and call
./isotropic_remeshing_example > out.off

#If you want to set the target_edge_length on the input change the file to that below and and call:
./isotropic_remeshing_example "data/pig.off" 0.1  >> out.off


isotropic_remeshing_example.cpp BELOW
#####################################################################


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
  unsigned int nb_iter = 3;

  //std::cout << "target_edge_length: " << target_edge_length << std::endl;

  //std::cout << "Split border...";

    std::vector<edge_descriptor> border;
    PMP::border_halfedges(faces(mesh),
      mesh,
      boost::make_function_output_iterator(halfedge2edge(mesh, border)));
    PMP::split_long_edges(border, target_edge_length, mesh);

  //std::cout << "done." << std::endl;

  //std::cout << "Start remeshing of " << filename
  //  << " (" << num_faces(mesh) << " faces)..." << std::endl;

  PMP::isotropic_remeshing(
      faces(mesh),
      target_edge_length,
      mesh,
      PMP::parameters::number_of_iterations(nb_iter)
      .protect_constraints(true)//i.e. protect border, here
      );

  std::cout << mesh  << std::endl;
  //std::cout << "Remeshing done." << std::endl;

    }
  return 0;
}
