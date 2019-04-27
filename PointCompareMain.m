function BaseEval=PointCompareMain(cSet,Qdata,dst,dataPath)
% evaluation function that calculates the distances from the 
% reference data (stl) to the evalution points (Qdata) and 
% the distances from the evaluation points to the reference


% reduce points to a 0.2 mm neighbourhood density
% As explained in the paper, "no two points are closer than 0.2 mm by 
% visiting the points randomly and removing nearby points residing in 
% a 0.2 mm neighborhood. This 0.2 mm sampling threshold is chosen to 
% match the estimated resolution of our [reference reconstruction].
tic
Qdata=reducePts_haa(Qdata,dst);
toc

% set stl datapath here
StlInName=[dataPath '/Points/stl/stl' sprintf('%03d',cSet) '_total.ply'];

% STL points has already been reduced to a 0.2 mm neighbourhood density
StlMesh = plyread(StlInName);
Qstl=[StlMesh.vertex.x StlMesh.vertex.y StlMesh.vertex.z]';

% explicitly compute an observability mask, and only evaluate stereo 
% reconstructed points located within it.
% The observability mask is obtained as the union of the individual 
% visibility mask estimates of the 49 or 64 structured light scans. 
% Load Mask (ObsMask) and Bounding box (BB) and Resolution (Res)
Margin=10;
MaskName=[dataPath '/ObsMask/ObsMask' num2str(cSet) '_' num2str(Margin) '.mat'];
% load ../MVS_Data/ObsMask/ObsMask1_10 % to see format of obsMask
load(MaskName, 'ObsMask', 'BB', 'Res')

% ObsMask[]_[].mat contains variables including ObsMask, BB and Res

MaxDist=60;
disp('Computing Data to Stl distances')
%       MaxDistCP(Qto, Qfrom,BB,MaxDist)
Ddata = MaxDistCP(Qstl,Qdata,BB,MaxDist);
toc

disp('Computing Stl to Data distances')
Dstl=MaxDistCP(Qdata,Qstl,BB,MaxDist);
disp('Distances computed')
toc

%use mask
%From Get mask - inverted & modified.
One=ones(1,size(Qdata,2));
Qv=(Qdata-BB(1,:)'*One)/Res+1;
Qv=round(Qv);

Midx1=find(Qv(1,:)>0 & Qv(1,:)<=size(ObsMask,1) & Qv(2,:)>0 & Qv(2,:)<=size(ObsMask,2) & Qv(3,:)>0 & Qv(3,:)<=size(ObsMask,3));
MidxA=sub2ind(size(ObsMask),Qv(1,Midx1),Qv(2,Midx1),Qv(3,Midx1));
Midx2=find(ObsMask(MidxA));

BaseEval.DataInMask(1:size(Qv,2))=false;
BaseEval.DataInMask(Midx1(Midx2))=true; %If Data is within the mask

BaseEval.cSet=cSet;
BaseEval.Margin=Margin;         %Margin of masks
BaseEval.dst=dst;               %Min dist between points when reducing
BaseEval.Qdata=Qdata;           %Input data points
BaseEval.Ddata=Ddata;           %distance from data to stl
BaseEval.Qstl=Qstl;             %Input stl points
BaseEval.Dstl=Dstl;             %Distance from the stl to data

load([dataPath '/ObsMask/Plane' num2str(cSet)],'P')
BaseEval.GroundPlane=P;         % Plane used to destinguise which Stl points are 'used'
BaseEval.StlAbovePlane=(P'*[Qstl;ones(1,size(Qstl,2))])>0; %Is stl above 'ground plane'
BaseEval.Time=clock;            %Time when computation is finished




