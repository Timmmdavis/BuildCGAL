
#Test each CGAL part
using DelimitedFiles
using Makie


#Load an existing mesh that we have
ModuleDir = dirname(dirname(pathof(CutAndDisplaceJulia)))
TestScript = joinpath(ModuleDir, "test", "test_TDvsEshelbyPennyCrack.jl")
include(TestScript)

#Convert this to discrete points on every triangle corner
Px=[P1[:,1]; P2[:,1]; P3[:,1]];
Py=[P1[:,2]; P2[:,2]; P3[:,2]];
Pz=[P1[:,3]; P2[:,3]; P3[:,3]];
#remove duplicate rows
Pnts=[Px Py Pz]
Pnts=unique(Pnts,dims=1) 
#Export it for adv front to read
OutputDirectory=CutAndDisplaceJulia.xyzExport(Pnts[:,1],Pnts[:,2],Pnts[:,3],"NewFracturePoints")

#Remesh and then read new file
(OutputDirectory)=BuildCGAL.AdvancingFrontCGAL(OutputDirectory)
(Points,Triangles)=CutAndDisplaceJulia.OFFReader(OutputDirectory)
#Clean up advancing front result
(FaceNormalVector,MidPoint)=CutAndDisplaceJulia.CreateFaceNormalAndMidPoint(Points,Triangles)
(P1,P2,P3)=CutAndDisplaceJulia.CreateP1P2P3( Triangles,Points )

#Draw it
using Makie
fig=CutAndDisplaceJuliaPlots.DrawMeshMakie(P1,P2,P3)
Makie.save("AfterAdvancingFrontCGALRemeshing.png", fig)

#Now lets see if its just one mesh
(OutputDirectoryCC)=BuildCGAL.ConnectedComponentsCGAL(OutputDirectory)

#Now lets try 
Flags=CutAndDisplaceJulia.ConnectedComponentsReader(OutputDirectoryCC)
#Should all be 1 (one mesh)

#Lets remesh
(OutputDirectoryRM)=BuildCGAL.PolygonRemeshingCGAL(OutputDirectory,0.1)
(Points,Triangles)=CutAndDisplaceJulia.OFFReader(OutputDirectoryRM)
#Clean up advancing front result
(FaceNormalVector,MidPoint)=CutAndDisplaceJulia.CreateFaceNormalAndMidPoint(Points,Triangles)
(P1,P2,P3)=CutAndDisplaceJulia.CreateP1P2P3( Triangles,Points )
#Draw it

fig=CutAndDisplaceJuliaPlots.DrawMeshMakie(P1,P2,P3)
Makie.save("PolyRemesh.png", fig)

#Lets remesh part of it (lower corner)
flag = (MidPoint[:, 2] .< 0) .& (MidPoint[:, 1] .< 0) 
TriNos=findall(flag)
Filename="TriNos.txt"
open(Filename, "w") do io
   writedlm(io, vec(TriNos))
end
TriNumbersTxtDir=string(pwd(),"\\",Filename)
(OutputDirectoryRMP)=BuildCGAL.PolygonRemeshingPatchCGAL(OutputDirectoryRM,TriNumbersTxtDir,0.05)
(Points,Triangles)=CutAndDisplaceJulia.OFFReader(OutputDirectoryRMP)
#Clean up advancing front result
(FaceNormalVector,MidPoint)=CutAndDisplaceJulia.CreateFaceNormalAndMidPoint(Points,Triangles)
(P1,P2,P3)=CutAndDisplaceJulia.CreateP1P2P3( Triangles,Points )
#Draw it
using Makie
fig=CutAndDisplaceJuliaPlots.DrawMeshMakie(P1,P2,P3)
Makie.save("PolyRemeshPatch.png", fig)

