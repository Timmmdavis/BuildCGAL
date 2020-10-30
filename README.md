# BuildCGAL
Builds [CGAL](https://www.cgal.org/)  and scripts for meshing

# Linux
If you are using Linux, you are lucky. Simply install CGAL using https://www.cgal.org/download/linux.html
Then just run:
```
include("path2file/Compile_CGAL_Meshing_Functions.jl")
```

# Windows
If you are Windows, less good but not impossible.
Firefox required!
Install it:
```
include("path2file/Compile_CGAL_Meshing_Functions.jl")
```
Compile it:
```
include("Compile_CGAL_Meshing_Functions.jl")
```
With some fiddling you should get this to work. 

# Calling a CGAL script:
Now you can mesh something easily: E.g.: 

```
OutputDirectory=CutAndDisplaceJulia.OFFExport(Points,Triangles,length(Triangles[:,1]),length(Points[:,1]),"BeforePolygonRemshing")
(OutputDirectory)=BuildCGAL.PolygonRemeshingCGAL(OutputDirectory,target_edge_length)
(Points,Triangles)=CutAndDisplaceJulia.OFFReader(OutputDirectory)
```

where
> Triangles = Triangles is a list where each row contains 3 row index locations in array 'Points' which contains the XYZ location of each corner of the triangle

> Points = Cols 2 3 and 4 are the xyz locations of one the corner points of a triangle.
