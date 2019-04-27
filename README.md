Original dataset and code at [DTU Robot Image Data Sets](http://roboimagedata.compute.dtu.dk/?page_id=36)

## Specification of Evaluation code

### BaseEvalMain_web.m	

This file is simply an encapsulation of the evaluation methods. To run the evaluation, simply put the datasets in place (as specified below) and run this function.

Use function `getPaths` (in getPaths.m) to specify where the source data are and where you would like to put the evaluation result.

```matlab
[dataPath,resultsPath]=getPaths();
```

Also, specify the evaluation algorithm and mvs representation.

```matlab
method_string='Tola';
representation_string='Points'; 
```

Run the function to get evaluation result. 

### PointCompareMain.m

The basic computation is done in function `PointCompareMain()`, which is called by `BaseEvalMain_web`. In this function, the reference points are loaded as well as ObsMask.

Reference points are stored as a `.ply` file and loaded with a third-party supported function `plyread()` （which is implemented in `plyread.m`）, whereas ObsMasj is previously processed and stored in a `.mat` file, alongside with some other paraemters.

After setting up the preparation job, the function first calculated the distances between mvs reconstruction and references (by function `MaxDistCP()` defined in `MaxDistCP.m`), and then use the ObsMask to filter out the desired values.

#### 1. Distance Computation

This step is completed by function `MaxDistCP(Qto,Qfrom,BB,MaxDist)`, which is defined in `MaxDistCP.m`. This function iterates over all points within `Qfrom`, and find the nearest point in `Qto` if exists by knnsearch algorithm. The computed distance is stored in another array returning to the caller function.

#### 2. ObsMask

In this part, the first step is to load a previous defined mask, which is a 3-dimension logical array, with each element (0, 0, 0) or (1, 1, 1) indicating if a point exists within the mask. A shrinking is calculated by given resolution (also a loaded term). This is because the mask has no distance specified for its size, so the real values are "remapped" to suit this mask.

```matlab
One=ones(1,size(Qdata,2));
Qv=(Qdata-BB(1,:)'*One)/Res+1;
Qv=round(Qv);
```

Next, the indices of all points with three dimensions all within the mask will be extracted by `sub2ind` and be transformed to a linear indices one dimension, and `find()` is used to extract all points within the mask.

```matlab
> Midx1=find(Qv(1,:)>0 & Qv(1,:)<=size(ObsMask,1) & Qv(2,:)>0 & Qv(2,:)<=size(ObsMask,2) & 	      
Qv(3,:)>0 & Qv(3,:)<=size(ObsMask,3));
> MidxA=sub2ind(size(ObsMask),Qv(1,Midx1),Qv(2,Midx1),Qv(3,Midx1));
> Midx2=find(ObsMask(MidxA));
```

Data are stored as a one dimensional array, which will be future processed by `BaseEval2Obj_web()`. The relative position of reconstruction and reference points within mask are also marked, which will be further used.

### BaseEval2Obj_web

This function generates the results as `.obj` file. If the points are within the mask (now a linear indices), it will be recorded. If the point is above referece plane, it will be colored red; otherwise will be colored green to blue.

## Backgrounds

### MVS algorithm

MVS is short for Multiview Stereo. It uses multiple images with known position info to estimate 3d objective.     MVS can be categorized according to 6 aspects:

1. scene representation

   > What kind of math model is used for representation of the reconstructed 3D scene. Common type are:
   >
   > - voxel
   > - level set
   > - polygon mesh
   > - depth map

2. photo consistency measure;

3. visible model;

4. shape prior;

5. reconstruction algorithm;

   > 1. 体素着色算法：从一个volumn中提取一个平面出来
   > 2. 通过递推的方法展开一个平面：在过程中最小化代价函数（based on voxels， level-set， mesh)
   > 3. 基于像方的匹配，生成深度图，并对不同图像间的深度图进行融合
   > 4. 提取特征点，拟合一个面来重建特征

6. initialization requirements

#### Evaluation:

Evaluation is based on two aspects: accuracy and completeness.

#### Reference

[MVS learning notes](<http://zhyan.tk/2017/07/03/mvs-learn-1-middlebury/>)



### [.ply](http://paulbourke.net/dataformats/ply/) file format

PLY file format, also known as Stanford Triangle Format. Each file includes a header which defines elements and properties of the file, followed by the data information of elements.

`ply` file has two encode format: binary and ASCII. Binary can make the data stored in a more compressed manner, while ASCII format is readable. 

Elements include vertices, faces, edges and even samples of range maps or triangle strips. Either ASCII or binary format uses ASCII to write its header. The following data resource are binary or ASCII.

The first line is 

```text
ply
```

to recognize the PLY file format.

The second line specifies which format this ply file is, there are currently three types:

```text
format ascii 1.0
format binary_little_endian 1.0
format binary_big_endian 1.0
```

1.0 means the file is standard version. In the header, comment can be included with `comment` in the front:

```text
comment This is a comment!
```



To transform a binary format `ply` to ASCII,  using the MATLAB function [`pcwrite()`](https://www.mathworks.com/help/vision/ref/pcwrite.html):

```matlab
pcwrite(ptCloud,'new.ply','Encoding','ascii');
```

Sample file structure for `ply` file is as follow:

```text
  Header
  Vertex List
  Face List
  (lists of other elements)
```

A sample header can be:

```
ply													{start of header}
format ascii 1.0
element vertex 2448349			{states data list representation and specifies total number}
property float x						{(x, y, z) is coordinate}
property float y						{each represents one property of each element (one line)}
property float z
property uchar red					{(r, g, b) is color data}
property uchar green
property uchar blue
property float nx						{(nx, ny, nz) is vertex normal vector}
property float ny
property float nz
end_header
```

More details can also be found on [wiki](<https://wikipedia.org/wiki/PLY>).

### .obj file format

The OBJ file format stores information about 3D models. It can encode surface geometry of a 3D model and can also store color and texture information. This format does not store any scene information (such as light position) or animations.

OBJ files do not require any sort of header, although it is common to begin the file with a comment line of some kind. Comment lines begin with a hash mark (#). Blank space and blank lines can be freely added to the file to aid in formatting and readability. Each non-blank line begins with a keyword and may be followed on the same line with the data for that keyword. Lines are read and processed until the end of the file. Lines can be logically joined with the line continuation character ( \ ) at the end of a line.

**File Details**

The most commonly encountered OBJ files contain only polygonal faces. To describe a polygon, the file first describes each point with the "v" keyword, then describes the face with the "f" keyword. The line of a face command contains the enumerations of the points in the face, as **1-based indices into the list of points**, in the order they occurred in the file. For example, the following describes a simple triangle:

```text
# Simple Wavefront file
v 0.0 0.0 0.0
v 0.0 1.0 0.0
v 1.0 0.0 0.0
f 1 2 3
```

[file for CAD and 3d printing](<https://all3dp.com/1/obj-file-format-3d-printing-cad/>)

[file format](<https://people.cs.clemson.edu/~dhouse/courses/405/docs/brief-obj-file-format.html>)

### MAT file format

mat file is the standard format for Matlab to store data. .mat is binary file, and can be stored and loaded with ASCII encoding.

MAT can be used to store the data in current workspace, so the program can be halted and resume at a next time from this point by loading the .mat file, restore data and continue execution.

### vertex normal vector ([smooth shading](<https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/shading-normals>))

Vertex normal vectors produce continuous shading across the surface of a polygon mesh, despite the fact that precisely the object that the mesh represents is not continuous as it is built from a collection of flat surfaces (the polygons or the triangles). We can compute a "fake smooth" normal by **linearly interpolating** the vertex normals defined at the triangle's vertices using the hit point barycentric coordinates.

![](https://www.scratchapixel.com/images/upload/shading-intro/shad-face-normals2.png?)



### Matlab functions

Use `load` to load some built-in sounds and can play with `sound()`.

```matlab
load laughter
sound(y,Fs)
```

#### load `.ply` file

Load with `pcread()` and view with `pcshow()`.

```matlab
ptCloud = pcread('teapot.ply');
pcshow(ptCloud); 
```

To transform the format of .ply file, (binary or ascii), using `pcwrite` function.

```matlab
pcwrite(ptCloud,'new.ply','Encoding','ascii');
```

#### indexing

In matlab, indexing uses brackets.

```matlab
>> c = [1,2,3,4,5];
>> c(4:5)
ans =
    15    48
```

#### [`kdtreesearcher`](<https://www.mathworks.com/help/stats/kdtreesearcher.html?searchHighlight=KDTreeSearcher&s_tid=doc_srchtitle#buipxhk-3>)

Creates a KDTreeSearcher model object using the kdtree algorithm.

```matlab
KDstl=KDTreeSearcher(SQto');
>> KDstl
KDstl = 
  KDTreeSearcher - properties:

       BucketSize: 50
         Distance: 'euclidean'
    DistParameter: []
                X: [198106×3 double]
```

#### [`knnsearch`](<https://www.mathworks.com/help/stats/knnsearch.html?searchHighlight=knnsearch&s_tid=doc_srchtitle#bt6axb5>)


#### Radial Distortion

Modern camera lenses are relatively free of geometric distortion. However, there is always a small remaining amount even with the most expensive lenses.

![](http://www.uni-koeln.de/~al001/radcor_files/rad027.png)

Radial distortion is most visible when taking pictures of vertical structures having straight lines which then appear curved.

More information is available at this [website](<http://www.uni-koeln.de/~al001/radcor_files/hs100.htm>).

#### mex file

**MEX file**. A **MEX file** is a type of computer **file** that provides an interface between MATLAB or Octave and functions written in C, C++ or Fortran. It stands for "MATLAB executable".

#### Frame of reference

In physics, a **frame of reference** (or **reference frame**) consists **of** an abstract coordinate system and the set **of**physical **reference** points that uniquely fix (locate and orient) the coordinate system and standardize measurements. In n dimensions, n + 1 **reference** points are sufficient to fully define a **reference frame**.

#### ICP

**Iterative closest point** (**ICP**) is an algorithm employed to minimize the difference between two clouds of points. ICP is often used to reconstruct 2D or 3D surfaces from different scans, to localize robots and achieve optimal path planning (especially when wheel odometry is unreliable due to slippery terrain), to co-register bone models, etc.

#### Odometry

**Odometry** is the use of data from motion sensors to estimate change in position over time. It is used in robotics by some legged or **wheeled** robots to estimate their position relative to a starting location.

## Paper notes
### Terminologies

> The term “adaptation” in computer science refers to a process where an interactive system (adaptive system) adapts its behaviour to individual users based on information acquired about its user(s) and its environment.

#### rendering

Rendering or image synthesis is the automatic process of generating a photorealistic or non-photorealistic image from a 2D or 3D model (or models in what collectively could be called a scene file) by means of computer programs

#### point cloud

A **point cloud** is a set of data points in space. Point clouds are generally produced by 3D scanners, which measure a large number of points on the external surfaces of objects around them.

Point clouds are often converted to polygon mesh or triangle mesh models through a process commonly referred to as **surface reconstruction**.

#### volume pixel grid

In Direct Volume Rendering (DVR), you’re rendering a data *grid*. This is a rectangular 3D volume which contains **data points with equidistant spacing**. Notice how different this is from traditional mesh-based rendering: **a mesh consists of a geometric description of triangles and their position, and all edges can have a variable length**. A data point in this grid is what you would call a *voxel*.

A voxel represents a value on a regular grid in three-dimensional space. As with pixels in a bitmap, voxels themselves do not typically have their position (their coordinates) explicitly encoded along with their values. Instead, rendering systems infer the position of a voxel based upon its position relative to other voxels (i.e., its position in the data structure that makes up a single volumetric image). In contrast to pixels and voxels, points and polygons are often explicitly represented by the coordinates of their vertices. A direct consequence of this difference is that polygons can efficiently represent simple 3D structures with lots of empty or homogeneously filled space, while voxels excel at representing regularly sampled spaces that are non-homogeneously filled.

#### 3D points

#### meshed surface

A polygon mesh is a collection of vertices, edges and faces that defines the shape of a polyhedral object in 3D computer graphics and solid modeling. The faces usually consist of triangles (triangle mesh), quadrilaterals, or other simple convex polygons, since this simplifies rendering, but may also be composed of more general concave polygons, or polygons with holes.

<img src="https://upload.wikimedia.org/wikipedia/commons/f/fb/Dolphin_triangle_mesh.png" width="400px" />

#### structured light

**Structured light** is the process of projecting a known pattern (often grids or horizontal bars) on to a scene. The way that these (structured lights) deform when striking surfaces allows vision systems to calculate the depth and surface information of the objects in the scene.

### Missing data

> **Middlebury Multi-View Stereo benchmark**: by fitting a closed surface to the reconstructed structured light points. Surface points were then added in areas with no reference data, by placing points on the reconstructed surface with the same density as the rest of the scanned surface.

We explicitly compute an **observability mask**, and only evaluate stereo reconstructed points located within it.  The observability mask is obtained as the **union of the individual visibility mask estimates of the 49 or 64 structured light scans**. 

A mask is hereby computed by making a voxel grid around the object in question, and casting rays from the camera to the reconstructed points. These rays are extended an extra 10 mm and all voxels along that
ray are marked as observed. The 10 mm depth assumption is needed to include stereo points reconstructed immediately behind the structured light reference points. The threshold of 10 mm was chosen as a tradeoff between including wrongly reconstructed MVS points in areas with reference data, and excluding correct MVS points in areas with no reference points.



### Evaluation

Target algorithm to be evaluated: MVS algorithms.

#### Accuracy

Accuracy is measured as the distance from the MVS reconstruction to the structured light reference.

#### Completeness

Completeness is measured from the reference to the MVS reconstruction.

Both MVS reconstructions and structured light references are represented as point clouds, and for each point in *one*, we calculate the closest distance to *the other*.

#### Preprocess

This decimation process ensures an unbiased evaluation across the whole reconstruction by keeping points in lower density areas, thus including outliers intact and reducing the effect of dense regions on the overall reconstruction accuracy.

The evaluation include both MVS reconstructed 3D points as well as meshed surfaces from these points. To
handle the surfaces meshes in our evaluation, we convert them back into point clouds. (Process: first supersampling the faces with a lower point density than 0.2 mm and then subsequently reducing the high point densities as described above. This gives an equal comparison of the effect of meshing, and the regularization of the result it implies.)

The distances of each 3D point are condensed into comparable statistics by computing the mean and median for the the *accuracy* and *completeness*. First remove outliers (all distances over 20 mm) to avoid biasing by them. The method to remove them is to obtain spurious, closed surfaces by meshing the stereo reconstructions.



### Summary

The evaluation is accomplished in two parts, missing data preprocessing and distance measuring. 

In the first part, an observability mask is constructed so that only points within the mask will be evaluated. (This is to omit the influence of missing ground truth values.)

In the second, part, the distance measurement is divided into two aspects: accuracy and completeness. For accuracy, the distance is computed from each point in the reconstruction with the closest points in reference points. For completeness, it is the other way around. The distance is computed from each point in reference to their closest points in reconstruction.

There are also some preparation jobs needed for distance measurements, such as pre-sampling for a uniform and unbiased measurement, and transformation of meshed surfaces back to point clouds.

At last, the evaluation is based on the statistical results, which is the mean and median of accuracy and completeness.
