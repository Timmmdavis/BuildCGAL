// Isotropic remeshing of a crack surface with element size graded towards its free edge (the
// crack front / tipline).
//
// Usage: graded_remeshing <mesh.off> <h> <hf> [growth=1.5] [iterations=8] [protect_front=0] [fixed.txt] [band=0] [smooth=10]
//   h       target edge length far from the front (the interior)
//   hf      target edge length at the front
//   growth  size ratio from one row of triangles to the next (1.2-1.6 is sensible)
//   protect_front  1: the front edges are kept exactly as given (not split, collapsed or moved).
//           Use this when the front has already been resampled at spacing hf (GradedRemesh in
//           CutAndDisplaceJulia does this, placing the points on a smooth curve). 0: front
//           vertices are added/removed by halving edges and slide along the input front.
//   fixed.txt  optional list of vertex numbers (0-based, one per line) that must not be moved or
//           removed, e.g. hand-placed rows of points next to the front.
//   band    distance from the front within which the size stays hf (the hand-placed rows);
//           grading starts from there: s(x) = min(h, hf + c*max(0, d(x)-band)).
//   smooth  iterations of angle smoothing after remeshing (0 = none).
// Writes the remeshed surface as OFF to stdout (same format as isotropic_remeshing_example).
//
// What it does
//   This is the same CGAL isotropic remeshing as isotropic_remeshing_example (border vertices
//   slide along the border, 15 relaxation steps), but instead of one target length the target at
//   a point x is
//       s(x) = min( h , hf + c*d(x) ),   c = 2*(growth-1)/sqrt(3)
//   where d(x) is the straight-line distance from x to the ORIGINAL front polyline. With rows of
//   equilateral triangles of height s*sqrt(3)/2 this makes each row `growth` times the size of the
//   one outside it.
//
// Curved cracks (dish shapes, warped sheets)
//   - Every new vertex is projected back onto the input surface (CGAL default), so the remeshed
//     crack keeps the shape of the input. It cannot be smoother than the input though: fine
//     triangles near the front lie on the input's (coarser) facets.
//   - The front only gets new vertices on its original segments, so the tipline is unchanged.
//   - d(x) is a 3D straight-line distance, not a distance measured along the surface. On a curved
//     sheet the straight line is never longer than the path along the surface, so a point can
//     only look *closer* to the front than it is. The mesh is then finer than asked, never
//     coarser. That would only matter if the sheet folds back on itself so that interior parts
//     come within a few h of the front.
//   - The front can be any closed loop or several loops (all border edges count as front).
#include <CGAL/Exact_predicates_inexact_constructions_kernel.h>
#include <CGAL/Surface_mesh.h>
#include <CGAL/Polygon_mesh_processing/remesh.h>
#include <CGAL/Polygon_mesh_processing/angle_and_area_smoothing.h>
#include <CGAL/AABB_tree.h>
#include <CGAL/AABB_traits_3.h>
#include <CGAL/AABB_segment_primitive_3.h>

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <memory>
#include <optional>
#include <string>
#include <vector>

typedef CGAL::Exact_predicates_inexact_constructions_kernel K;
typedef K::FT FT;
typedef K::Point_3 Point_3;
typedef K::Segment_3 Segment_3;
typedef CGAL::Surface_mesh<Point_3> Mesh;
typedef boost::graph_traits<Mesh>::vertex_descriptor vertex_descriptor;
typedef boost::graph_traits<Mesh>::halfedge_descriptor halfedge_descriptor;
typedef std::vector<Segment_3>::const_iterator SegIt;
typedef CGAL::AABB_segment_primitive_3<K, SegIt> Primitive;
typedef CGAL::AABB_traits_3<K, Primitive> Traits;
typedef CGAL::AABB_tree<Traits> Tree;
namespace PMP = CGAL::Polygon_mesh_processing;

// The sizing field, following the PMPSizingField concept (same layout as CGAL's
// Uniform_sizing_field, but the size depends on the distance to the front).
class Front_graded_sizing_field
  : public PMP::internal::Sizing_field_base<Mesh,
             boost::property_map<Mesh, CGAL::vertex_point_t>::const_type>
{
public:
  typedef FT FT_;
  Front_graded_sizing_field(std::shared_ptr<Tree> tree, FT h, FT hf, FT growth, FT band, const Mesh& m)
    : m_tree(tree), m_h(h), m_hf(hf), m_c(2.0 * (growth - 1.0) / std::sqrt(3.0)), m_band(band),
      m_vpm(get(CGAL::vertex_point, m)) {}

  // Target length at a point
  FT size_at(const Point_3& p) const
  {
    const FT d = std::sqrt(CGAL::to_double(m_tree->squared_distance(p)));
    return (std::min)(m_h, m_hf + m_c * (std::max)(FT(0), d - m_band));
  }

  FT at(const vertex_descriptor v, const Mesh&) const { return size_at(get(m_vpm, v)); }

  // An edge is judged by the target length at its midpoint
  FT target_length(const vertex_descriptor a, const vertex_descriptor b) const
  {
    return size_at(CGAL::midpoint(get(m_vpm, a), get(m_vpm, b)));
  }

  std::optional<FT> is_too_long(const vertex_descriptor a, const vertex_descriptor b, const Mesh&) const
  {
    const FT sqlen = CGAL::squared_distance(get(m_vpm, a), get(m_vpm, b));
    const FT sqt = CGAL::square(4. / 3. * target_length(a, b));
    if (sqlen > sqt) return sqlen / sqt;
    return std::nullopt;
  }

  std::optional<FT> is_too_short(const halfedge_descriptor h, const Mesh& m) const
  {
    const vertex_descriptor a = source(h, m), b = target(h, m);
    const FT sqlen = CGAL::squared_distance(get(m_vpm, a), get(m_vpm, b));
    const FT sqt = CGAL::square(4. / 5. * target_length(a, b));
    if (sqlen < sqt) return sqlen / sqt;
    return std::nullopt;
  }

  Point_3 split_placement(const halfedge_descriptor h, const Mesh& m) const
  {
    return CGAL::midpoint(get(m_vpm, target(h, m)), get(m_vpm, source(h, m)));
  }

  void register_split_vertex(const vertex_descriptor, const Mesh&) {}

private:
  std::shared_ptr<Tree> m_tree;
  FT m_h, m_hf, m_c, m_band;
  boost::property_map<Mesh, CGAL::vertex_point_t>::const_type m_vpm;
};

int main(int argc, char* argv[])
{
  if (argc < 4) {
    std::cerr << "Usage: " << argv[0] << " <mesh.off> <h> <hf> [growth=1.5] [iterations=8]" << std::endl;
    return 2;
  }
  std::ifstream input(argv[1]);
  Mesh mesh;
  if (!input || !(input >> mesh) || !CGAL::is_triangle_mesh(mesh)) {
    std::cerr << "Not a valid input file: " << argv[1] << std::endl;
    return 1;
  }
  const FT h = std::atof(argv[2]);
  const FT hf = std::atof(argv[3]);
  const FT growth = argc > 4 ? std::atof(argv[4]) : 1.5;
  const unsigned int nb_iter = argc > 5 ? std::atoi(argv[5]) : 8;
  const bool protect_front = argc > 6 && std::atoi(argv[6]) == 1;
  const std::string fixed_file = argc > 7 ? argv[7] : "";
  const FT band = argc > 8 ? std::atof(argv[8]) : 0.0;
  const unsigned int smooth_iter = argc > 9 ? std::atoi(argv[9]) : 10;
  if (!(h > 0) || !(hf > 0) || hf > h || !(growth > 1)) {
    std::cerr << "Need h > 0, 0 < hf <= h and growth > 1" << std::endl;
    return 2;
  }

  // The front: every border edge of the input, kept fixed as the reference for d(x)
  std::vector<Segment_3> front;
  for (halfedge_descriptor hd : halfedges(mesh))
    if (is_border(hd, mesh))
      front.emplace_back(mesh.point(source(hd, mesh)), mesh.point(target(hd, mesh)));
  if (front.empty()) {
    std::cerr << "Mesh has no border (closed surface): nothing to grade towards" << std::endl;
    return 1;
  }
  auto tree = std::make_shared<Tree>(front.begin(), front.end());
  tree->accelerate_distance_queries();

  Front_graded_sizing_field sizing(tree, h, hf, growth, band, mesh);

  // Vertices that must stay where they are (hand-placed rows next to the front)
  auto vcm = mesh.add_property_map<vertex_descriptor, bool>("v:fixed", false).first;
  if (!fixed_file.empty() && fixed_file != "-") {
    std::ifstream ff(fixed_file);
    std::size_t i;
    while (ff >> i)
      if (i < num_vertices(mesh)) put(vcm, vertex_descriptor(static_cast<Mesh::size_type>(i)), true);
  }

  if (protect_front) {
    // Front edges flagged as constrained and protected: never split, collapsed or moved
    auto ecm = mesh.add_property_map<boost::graph_traits<Mesh>::edge_descriptor, bool>("e:front", false).first;
    for (auto e : edges(mesh))
      if (is_border(e, mesh)) put(ecm, e, true);
    PMP::isotropic_remeshing(
        faces(mesh), sizing, mesh,
        CGAL::parameters::number_of_iterations(nb_iter)
            .edge_is_constrained_map(ecm)
            .vertex_is_constrained_map(vcm)
            .protect_constraints(true)
            .number_of_relaxation_steps(15));
    mesh.remove_property_map(ecm);
  } else {
    PMP::isotropic_remeshing(
        faces(mesh), sizing, mesh,
        CGAL::parameters::number_of_iterations(nb_iter)
            .vertex_is_constrained_map(vcm)
            .relax_constraints(true)          // border vertices slide along the border
            .collapse_constraints(true)
            .number_of_relaxation_steps(15)); // more isotropic
  }
  // Angle smoothing to lift the smallest angles where the size changes (front and fixed vertices
  // held in place; vertices are put back on the input surface).
  {
    for (vertex_descriptor v : vertices(mesh))
      if (is_border(v, mesh)) put(vcm, v, true);
    PMP::angle_and_area_smoothing(mesh,
        CGAL::parameters::number_of_iterations(smooth_iter)
            .vertex_is_constrained_map(vcm)
            .use_area_smoothing(false)
            .use_safety_constraints(true));
  }
  mesh.remove_property_map(vcm);

  mesh.collect_garbage();
  std::cout.setf(std::ios::fixed, std::ios::floatfield);
  std::cout.precision(13);
  std::cout << mesh << std::endl;
  return 0;
}
