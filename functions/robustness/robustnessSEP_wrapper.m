dataPath     = getenv('GADIR');
matName      = 'robustness_amplitude_singleTrial.mat';

stimType1    = {'median', 'tibial'};

srmr_nr = str2num(dataPath(19));
if  srmr_nr == 1
    stimType2    = {'mixed'};
elseif srmr_nr == 2
    stimType2    = {'d1', 'd2', 'd12'};
end

aType        = {'CCA', 'target'};
removeNaNs   = 1;
trialSizes   = [5 10 1000];
noExperiment = 1000;
subjectSizes = [5 5 36];
indsubjectPlot = 0;
sampleVaryPlot = 1;
doPlots        = 1;
savePlots      = 0;


for istim1 = 1:length(stimType1)
    for istim2 = 1:length(stimType2)
        for ichan = 1:length(aType)
            robustnessSEP(dataPath, matName, stimType1{istim1}, stimType2{istim2}, aType{ichan}, removeNaNs, ...
                trialSizes, noExperiment, subjectSizes, indsubjectPlot,sampleVaryPlot, doPlots, savePlots)
        end
    end
end