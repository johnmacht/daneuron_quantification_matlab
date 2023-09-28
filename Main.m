%% startup scripts specific to LCSB HCS setup
%% adaption needed for any other infrastructure


%% Collect Linux\Slurm metadata
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('Job is running on node:')
[~, node] = system('hostname');
disp(node)
disp('Job is run by user:')
[~, user] = system('whoami');
disp(user)
disp('Current slurm jobs of current user:')
[~, sq] = system(['squeue -u ', user]);
disp(sq)
tic
disp(['Start: ' datestr(now, 'yyyymmdd_HHMMSS')])
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

addpath(genpath('/work/projects/lcsb_hcs/Library/hcsforge'))
addpath(genpath('/work/projects/lcsb_hcs/Library/hcsIris'))

if ~exist('InPath') % if Inpath is provided  via command line, use that one
    InPath = '<define_inPath>';
end

MesPath = ls([InPath, '/*.mes']); MesPath = MesPath(1:end-1); % remove line break
MetaData = f_CV8000_getChannelInfo(InPath, MesPath);

if ~exist('OutPath') % if Outpath is provided  via command line, use that one
    OutPath = '<define_outPath>';
end

%% Prepare folders
mkdir(OutPath)
PreviewPath = [OutPath, filesep, 'Previews'];
mkdir(PreviewPath)

%% Log
%f_LogDependenciesLinux(mfilename, OutPath)


%% Load Metadata
ObjectsAll = {};
%Layout = Iris_GetLayout(InPath);
%MetaData = f_CV8000_getChannelInfo(InPath, MesPath);
InfoTable = MetaData.InfoTable{:};
Wells = unique(InfoTable.Well);
fieldProgress = 0;
for w = 1:numel(Wells)
    WellThis = Wells{w};
    InfoTableThisWell = InfoTable(strcmp(InfoTable.Well, WellThis),:);
    FieldsThisWell = unique(InfoTableThisWell.Field);
    for f = 1:numel(FieldsThisWell)
        fieldProgress = fieldProgress + 1;
        FieldThis = FieldsThisWell{f};
        InfoTableThisField = InfoTableThisWell(strcmp(InfoTableThisWell.Field, FieldsThisWell{f}),:);
        ChannelsThisField =  unique(InfoTableThisField.Channel);
        ImPaths = cell(1, numel(ChannelsThisField));
        for c = 1:numel(ChannelsThisField)
            ChannelThis = ChannelsThisField{c};
            InfoTableThisChannel = InfoTableThisField(strcmp(InfoTableThisField.Channel,ChannelThis),:);
            InfoTableThisChannel = sortrows(InfoTableThisChannel, 'Plane', 'ascend');
            chThisPaths = cell(numel(ChannelsThisField),1);
            for p = 1:height(InfoTableThisChannel)
                chThisPaths{p} = InfoTableThisChannel{p, 'file'}{:};
                %for t = 1:height()
            end
            ImPaths{c} = chThisPaths;
            MesFile = MetaData.MeasurementSettingFileName;
        end
       FieldMetaData{fieldProgress} = {ImPaths, MesFile, Wells{w}, FieldsThisWell{f}};
    end
end

disp('Debug point')
FieldMetaDataTable = cell2table(vertcat(FieldMetaData{:}))

parfor i = 1:numel(FieldMetaData) % 265
% for i = 265:267
    try
      
        MesFile = FieldMetaData{i}{2};
        ch1files = sort(FieldMetaData{i}{1}{1}(1:3));
        ch1Collector = cellfun(@(x) imread(x), ch1files, 'UniformOutput', false);
        ch1 = cat(3,ch1Collector{:}); % vol(ch1, 0, 2000) Hoechst
    
        ch2files = sort(FieldMetaData{i}{1}{2}(1:3));
        ch2Collector = cellfun(@(x) imread(x), ch2files, 'UniformOutput', false);
        ch2 = cat(3,ch2Collector{:}); % vol(ch2, 0, 800) Map2
        
        ch3files = sort(FieldMetaData{i}{1}{3}(1:3));
        ch3Collector = cellfun(@(x) imread(x), ch3files, 'UniformOutput', false);
        ch3 = cat(3,ch3Collector{:}); % vol(ch3, 0, 2000) TH
        
        ch4files = sort(FieldMetaData{i}{1}{4}(1:3));
        ch4Collector = cellfun(@(x) imread(x), ch4files, 'UniformOutput', false);
        ch4 = cat(3,ch4Collector{:}); % vol(ch4, 0, 1000) GFP

        WellThis = FieldMetaData{i}{3};
        FieldThis = FieldMetaData{i}{4};
        
        %Objects = f_imageAnalysis(ch1, ch2, ch3, ch4, WellThis, FieldThis, MesFile, PreviewPath, Layout);
        Objects = f_imageAnalysis(ch1, ch2, ch3, ch4, WellThis, FieldThis, MesFile, PreviewPath);
        ObjectsAll{i} = Objects;
        
    catch ME
        disp(['Error for i ', num2str(i)])
        errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
            ME.stack(1).name, ME.stack(1).line, ME.message);
        fprintf(1, '%s\n', errorMessage);
        continue
    end

end

Data = vertcat(ObjectsAll{:});
save([OutPath, filesep, 'data.mat'], 'Data');
writetable(Data, [OutPath, filesep, 'data.csv'])
disp('Script completed successfully')
