# BuildCGAL
Builds [CGAL](https://www.cgal.org/) with some additional julia functions you can call for meshing.

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
include(raw"path2file\Compile_CGAL_Meshing_Functions.jl")
```
Then call BuildGCAL
```
using BuildCGAL
```
If you get an error about directorys, create a new folder inside "path2file/examples" called "BuildDir". Now compile it using:
```
BuildCGAL.Compile_CGAL_Meshing_Functions()
```
If you get an error about 7z make sure you have the following working version of the cmd version of 7zip on path: 7-Zip 19.00 (x64), from https://www.7-zip.org/download.html. You will get an error that not everything is working. So call:
```
include(raw"path2file\DownloadAndCheckAllCGALCompilerDependencies.jl")
```
Which installs all the components to build CGAL. Then calling
```
BuildCGAL.Compile_CGAL_Meshing_Functions()
```
Should start compiling the code
With some fiddling you should get this to work. 

# Testing the CGAL scripts:
Now you can mesh something easily: E.g.: 

```
cd('desiredpath')
] test BuildCGAL
```

where
> Triangles = Triangles is a list where each row contains 3 row index locations in array 'Points' which contains the XYZ location of each corner of the triangle
> Points = Cols 2 3 and 4 are the xyz locations of one the corner points of a triangle.
