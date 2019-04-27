function Dist = MaxDistCP(Qto,Qfrom,BB,MaxDist)

Dist=ones(1,size(Qfrom,2)) * MaxDist;
% size(Qfrom,2) returns the size of Qform in the second dimension

% calculates the partition unit of points in three dimensions
% MaxDist is set as a [size] for neighborhood
Range=floor((BB(2,:)-BB(1,:))/MaxDist);

tic
Done=0;
LookAt=zeros(1,size(Qfrom,2));

% Both MVS reconstructions and structured light references are represented
% as point clouds, and for each point in one (of reconstruction or 
% reference), we calculate the closest distance to the other.
for x=0:Range(1)
    for y=0:Range(2)
        for z=0:Range(3)
            % the for loop divid the 3-d box space into X*Y*Z cells 
            % x, y, z specifies a partition unit,  low and high sets size
            Low=BB(1,:)+[x y z]*MaxDist;
            High=Low+MaxDist;
            
            % find all points within the cell to calculate from
            idxF=find(Qfrom(1,:)>=Low(1) & Qfrom(2,:)>=Low(2) & Qfrom(3,:)>=Low(3) &...
                Qfrom(1,:)<High(1) & Qfrom(2,:)<High(2) & Qfrom(3,:)<High(3));
            SQfrom=Qfrom(:,idxF);
            LookAt(idxF)=LookAt(idxF)+1; %Debug
            
            % get the range of points to be considered for calculation
            Low=Low-MaxDist;
            High=High+MaxDist;
            idxT=find(Qto(1,:)>=Low(1) & Qto(2,:)>=Low(2) & Qto(3,:)>=Low(3) &...
                Qto(1,:)<High(1) & Qto(2,:)<High(2) & Qto(3,:)<High(3));
            SQto=Qto(:,idxT);
            
            
            if(isempty(SQto))
                Dist(idxF)=MaxDist;
            else
                % create a KDTreeSearcher model object for input
                KDstl=KDTreeSearcher(SQto');
                
                % [Idx, D] = knnsearch(X,Y) finds the nearest neighbor in X for each 
                % query point in Y and returns the indices of the nearest neighbors 
                % in Idx, a column vector. Idx has the same number of rows as Y.
                [~,SDist] = knnsearch(KDstl,SQfrom');
                
                % set the nearset-point distsances for points in idxF as
                % SDist.
                Dist(idxF)=SDist;
            end
            % [Done] is used for debug, to cehck if all points have been traversed.
            Done=Done+length(idxF);
        end
    end
end

