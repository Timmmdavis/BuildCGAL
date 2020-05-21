//Inputs: mesh.off; TriEdgeLength(Int); TriNos.txt
// 1. The input mesh
// 2. length of tri edges you want; 
// 3. a txt file that is a list of numbers (tri nos) where each is seperated by a new line.
//these are the patches of the mesh we will work on.
// //note index 1 is first tri, CGAL and c++ use index 0 as start which is accounted for:

//PS C:\Users\Berlin\.julia\packages\BuildCGAL\xeG9g\examples\BuildDirPolyMesh> .\isotropic_remeshing_of_patch_example.exe "C:\Users\Berlin\.julia\packages\BuildCGAL\xeG9g\examples\Polygon_mesh_processing\data\pig.off" 4 ".\data\TimsTriNos.txt" >> results.txt
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
typedef boost::graph_traits<Mesh>::face_descriptor     face_descriptor;

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


  if (argc > 3)
  {
    const char* filename2 = (argc > 3) ? argv[3] : "data/pig.off";
    std::ifstream myfile(filename2); //file opening constructor
    //Operation to check if the file opened
    if ( myfile.is_open() )
    {
      std::vector<int> TriNos;
      int id;
      char delimiter;
      // Read the file.
      //myfile.ignore(1000, '\n');
      while(myfile >> id)
      {
          TriNos.push_back({id});
      }

  unsigned int nb_iter = 5;    

  /*
  std::cout << "Desired edge length:" << std::endl;
  std::cout << target_edge_length << std::endl;
  std::cout << "no of tris we will work on:" << std::endl;
  std::cout << TriNos.size() << std::endl;
  std::cout << "tri nos we are going to work on (indexing from 1)" << std::endl;
  for(int i=0; i<TriNos.size(); ++i)
    std::cout << TriNos[i] << ' ';


  std::cout << "Split border...";

    std::vector<edge_descriptor> border;
    PMP::border_halfedges(faces(mesh),
      mesh,
      boost::make_function_output_iterator(halfedge2edge(mesh, border)));
    PMP::split_long_edges(border, target_edge_length, mesh);


  std::cout << "done." << std::endl;

  std::cout << "Start remeshing of " << filename
            << " (" << num_faces(mesh) << " faces,";
  */            

  std::vector<face_descriptor> seed, patch;
  Mesh::Property_map<face_descriptor,int> selected
    = mesh.add_property_map<face_descriptor,int>("f:selected",0).first;
  
  //Selecting the faces we loaded in
  for(int i=0; i<TriNos.size(); ++i)
    patch.push_back(*(faces(mesh).first+TriNos[i]-1));

  //CGAL::expand_face_selection(seed, mesh, 1, selected, std::back_inserter(patch));

  /*
  //Priting the selection (note the indexing from 0)
  std::cout << " and patch of n tris; n= " << patch.size() << std::endl;
  std::cout << " list of selected faces (indexing from 0)" << std::endl;
  for(int i=0; i<patch.size(); ++i)
    std::cout << patch[i] << ' ';
  */

  PMP::isotropic_remeshing(patch,
                           target_edge_length,
                           mesh,
                           PMP::parameters::number_of_iterations(nb_iter)
                           .face_patch_map(selected)
                           .protect_constraints(true)//i.e. protect border, here
                           );

  //Output precision to match Julias. 
  std::cout.setf( std::ios::fixed, std:: ios::floatfield ); // floatfield set to fixed
  std::cout.precision(13);
  std::cout << mesh  << std::endl;
  //std::cout << "Remeshing done." << std::endl;

    } //End of my file is open: the file containing tri ids
    else
    {
        std::cerr<<"ERROR: The file isnt open.\n";
    }
  }  //input 2
  }  //input 3
  return 0;
}
