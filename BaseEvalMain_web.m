clear
close all
format compact
% clc

% script to calculate distances have been measured for all included scans (UsedSets)
addpath('MeshSupSamp_web/x64/Release');

[dataPath,resultsPath]=getPaths();

% specify which algorithm is to evaluate
method_string='Tola';
    % method_string='Camp';
    % method_string='Furu';

%mvs representation 'Points' or 'Surfaces'
representation_string='Points'; 

% setting up the mode for evaluation
switch representation_string
    case 'Points'
        eval_string='_Eval_IJCV_';              % results naming
        settings_string='';
    case 'Surfaces'
        eval_string='_SurfEval_Trim_IJCV_';     % results naming
        settings_string='_surf_11_trim_8';      % poisson settings for surface input
end

% l3 is the setting with all lights on, l7 is randomly sampled between the 7 settings (index 0-6)
light_string='l3'; %'l7'; 

% get sets used in evaluation
if(strcmp(light_string,'l7'))           % strcmp returns 1 if equal and 0 if not
    UsedSets=GetUsedLightSets;          % the function getUsedLightSets() has no arguments
    eval_string=[eval_string 'l7_'];    % single quotation mark, concatenate string.
else
    UsedSets=GetUsedSets();             % the function getUsedSets() has no arguments
end

% set threshold for sampling (min dist between points when reducing)
dst=0.2;

for cSet=UsedSets   % run through all sets used in the evaluation
    
    % input data name
    DataInName=[dataPath ...
        sprintf('/%s/%s/%s%03d_%s%s.ply', representation_string, ...
                lower(method_string),lower(method_string),cSet,...
                light_string,settings_string)];
                % lower() convert string to lowercase
                % '%03d' fill 0 to integer to 3 digits if not enough
    
    % results name
    EvalName=[resultsPath method_string eval_string num2str(cSet) '.mat'];
    
    if(~exist(EvalName,'file'))     % check if file is already computed
               
        tic    % start timing
        
        Mesh = plyread(DataInName);                             % toc: this step takes within 30s. 
        % plyread() reads a .ply file and generate a structure that
        % contains all relavant information, may include color
        Qdata=[Mesh.vertex.x Mesh.vertex.y Mesh.vertex.z]';     % stores the vertices position in Qdata
        
        if(strcmp(representation_string,'Surfaces'))
            % upsample triangles
            Tri=cell2mat(Mesh.face.vertex_indices)';
            Qdata=MeshSupSamp(Qdata,Tri,dst);
        end
        toc
        
        BaseEval=PointCompareMain(cSet,Qdata,dst,dataPath);
        
        disp('Saving results'), drawnow
        toc
        save(EvalName,'BaseEval');
        toc
        
        % write obj-file of evaluation
        BaseEval2Obj_web(BaseEval,method_string, resultsPath)
        toc
    end
end

% celebrate with a fanfare
load laughter
sound(y,Fs)





