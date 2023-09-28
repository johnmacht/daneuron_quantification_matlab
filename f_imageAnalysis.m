%% main image analysis scripts
% individual channels adjusted to match recorded channels in Yokogawa generated images

%% define channel order for input
function [Summary] = f_imageAnalysis(chNuc, chMap2, chTH, chGFP, WellThis, FieldThis, MesFile, PreviewPath)

%   Segmentation of indivual channels and generation of masks

    %% segment nuclei (DAPI)
    chNuc = max(chNuc, [], 3);% %imtool(chNuc,[])
    NucMed = medfilt2(chNuc);% %imtool(NucMed,[])
    NucDoG = imfilter(NucMed, fspecial('gaussian', 301, 3) - fspecial('gaussian', 301, 101), 'symmetric');% %imtool(NucDoG, [])
    NucMask = NucDoG > 3; % %imtool(NucMask,[])
    NucMask = bwareaopen(NucMask,100);
    
    %% segment MAP2
    chMap2 = max(chMap2, [], 3);
    Map2Med = medfilt2(chMap2);% %imtool(Map2Med,[])
    Map2DoG = imfilter(Map2Med, fspecial('gaussian', 55, 1) - fspecial('gaussian', 55, 11), 'symmetric');% %imtool(Map2DoG, [])
    Map2Mask = Map2DoG > 20; % %imtool(Map2Mask,[])
    Map2Mask = bwareaopen(Map2Mask,100);

    %% segment TH
    chTH = max(chTH, [], 3);% %imtool(ch1,[])
    THMed = medfilt2(chTH);% %imtool(THMed,[])
    THDoG = imfilter(THMed, fspecial('gaussian', 55, 1) - fspecial('gaussian', 55, 11), 'symmetric');% %imtool(THDoG, [])
    THMask = THDoG > 100; % %imtool(THMask,[])
    THMask = bwareaopen(THMask,100);

% Feature extraction

    Summary = table();
    Summary.Well = WellThis;
    Summary.Field = FieldThis;
    Summary.NucArea = sum(NucMask(:));
    Summary.Map2AreaByNucArea = sum(Map2Mask(:)) / Summary.NucArea;
    Summary.TH2AreaByNucArea = sum(THMask(:)) / Summary.NucArea;
    Summary.MeanGFPinMap2 = mean(chGFP(Map2Mask));
    Summary.MeanTHinMap2 = mean(chTH(Map2Mask));
    Summary.MeanGFPinTH = mean(chGFP(THMask));
    Summary.MeanMap2inTH = mean(chMap2(THMask));
    Summary.Map2Area = sum(Map2Mask(:));
    Summary.THArea = sum(THMask(:));
    Summary.MeanTHinTH = mean(chTH(THMask));
    Summary.MeanMap2inMap2 = mean(chMap2(Map2Mask));
    
% Generation of image file output (Previews)

    imSize = size(NucMask);
    %% add scale bar
    [BarMask, BarCenter] = f_barMask(100, 0.323, imSize, imSize(1)-50, 50, 20); 
    
    %% adjust Nuclei preview
    NucPreview = f_imoverlayIris(imadjust(chNuc, [0 0.2], [0 1]), imdilate(bwperim(NucMask),strel('disk', 1)), [0 0 1]);
    NucPreview = f_imoverlayIris(NucPreview, BarMask, [1 1 1]);
    
    %% adjust TH signal preview
    THPreview = f_imoverlayIris(imadjust(chTH, [0 0.01], [0 1]), imdilate(bwperim(THMask),strel('disk', 1)), [1 0 0]);
    THPreview = f_imoverlayIris(THPreview, BarMask, [1 1 1]);
    
    %% adjust MAP2 signal preview
    Map2Preview = f_imoverlayIris(imadjust(chMap2, [0 0.1], [0 1]), imdilate(bwperim(Map2Mask),strel('disk', 0)), [1 0 0]);
    Map2Preview = f_imoverlayIris(Map2Preview, BarMask, [1 1 1]);
    
    %% define output files
    label = [WellThis, '_', FieldThis];
    NucPreviewPath = [PreviewPath, filesep, label, '_Nuc.png'];
    NeuronPreviewPath = [PreviewPath, filesep, label, '_Neuron.png'];
    THPreviewPath = [PreviewPath, filesep, label, '_TH.png'];
    Map2PreviewPath = [PreviewPath, filesep, label, '_Map2.png'];
    
    imwrite(NucPreview, NucPreviewPath)
    imwrite(THPreview, THPreviewPath)
    imwrite(Map2Preview, Map2PreviewPath)

end

