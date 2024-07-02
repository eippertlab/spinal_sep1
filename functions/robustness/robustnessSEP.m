% Function to assess the robustness of SEPs at the level of individual
% subjects (for varying number of trials) and also at group level (for varying number of trials x subjects).
% Merve Kaptan, mkaptan@cbs.mpg.de, 2022 (now at mkaptan@stanford.edu)

%% INPUTs
% dataPath   = string, path to data directory
% matName    = string, name of the data matrix
% stimType1  = string, type of stimulation; median or tibial
% stimType2  = string, type of stimulation; mixed or d1 etc.
% aType      = string, type of analysis; CCA or target
% removeNaNs = double or logical, remove nan values from the data or not (prior to robustness estimation)
% trialSizes = double, 1 x 3 or 3 x 1 matrix- number of trials to sample, 1st value; min number, 2nd value: step size, 2nd value max number of trials to sample
% noExperiment = double, how many times to repeat the 'experiment' / resampling
% subjectSizes = double, 1 x 3 or 3 x 1 matrix- number of subjects to sample, 1st value; min number, 2nd value: step size, 2nd value max number of subjects to sample
% indsubjectPlot = double or logical, create single-subject robustness plots
% sampleVaryPlot = double or logical, create group-level robustness plots
% doPlots     = double or logical, create the plots or not
% savePlots   =  double or logical, save the plots or not

%% OUTPUT
% .svg figures (depending on the type of the plot that is chosen)

%% DEPENDENCIES
% To create distinct colors for the line plots following function by Tim Holy was used: 
% https://de.mathworks.com/matlabcentral/fileexchange/29702-generate-maximally-perceptually-distinct-colors
%%
function robustnessSEP(dataPath, matName, stimType1, stimType2, aType, removeNaNs, ...
    trialSizes, noExperiment, subjectSizes, indsubjectPlot,sampleVaryPlot, doPlots, savePlots)

% load the data
load(fullfile(dataPath, matName))

% get the data you are interested in
myData = eval(['amplitudes.' stimType1 '.' stimType2 '.esg_' aType '.data'])

%% what about the NaNs? Do you want them or not?
if removeNaNs
    
    % first find the indices of NaN
    
    for sub = 1:size(myData,1);
        
        if ~isempty(find(isnan(myData(sub,:))))
            
            NaNidx(sub,1) = min(find(isnan(myData(sub,:))));
            
        elseif isempty(find(isnan(myData(sub,:))))
            
            NaNidx(sub,1) = size(myData,2);
            
            
        end
        
    end
    
    myData = myData(:,1:min(NaNidx)-1);
    
else
    
    myData = myData;
    
end
%%
trials = [trialSizes(1):trialSizes(2):trialSizes(end) trialSizes(end)];

subjects = [subjectSizes(1):subjectSizes(2):subjectSizes(end) subjectSizes(end)];


if indsubjectPlot
    
    for s = 1:size(myData,1)
        
        clear subjSample
        subjSample = myData(s,:);
        
        for bIdx = 1:noExperiment
            
            for t = 1:numel(trials)
                
                y = datasample(subjSample, trials(t), 2);
                [~,p(bIdx,s,t)] = ttest(y);
                clear y
            end
            
        end
    end
    
    
    for t = 1:numel(trials)
        
        for s = 1:size(myData,1)
            
            Probs(s,t) = sum(p(:,s,t) <0.05)/numel(p(:,s,t));
            
        end
    end
    
    
    if doPlots
        
        figure; imagesc(trialSizes,1:size(myData,1),Probs); hold on
        colormap(jet)
        caxis([0 1])
        colorbar
        ylabel('Subjects')
        xlabel('Number of trials')
        hcb = colorbar;
        hcb.Title
        hcb.Title.String = "Proportion of significant experiments";
        
        
        title(['N = 1 (for each subject) ' stimType1 ' ' stimType2 ' '   aType ])
        
        
        if savePlots
            
            print(gcf, '-painters','-dsvg', ...
                fullfile(datapath, [ matName '_' stimType1 '_' stimType2 '_' aType '_INDsubjects.svg'] ));
            
            
        end
        
        
    end
    
    
end


if sampleVaryPlot
    
    
    for bIdx = 1:noExperiment
        
        for s = 1:numel(subjects)
            
            clear subjSample
            subjSample = datasample(myData, subjects(s),1);
            
            for t = 1:numel(trials)
                
                y = datasample(subjSample, trials(t), 2);
                [~,p(bIdx,s,t)] = ttest(mean(y,2));
                
                clear y
                
            end
            
        end
    end
    
    
    
    for t = 1:numel(trials)
        for s = 1:numel(subjects)
            
            Probs(s,t) = sum(p(:,s,t) <0.05)/numel(p(:,s,t));
            
        end
    end
    
    
    if doPlots
        
        plotColors = distinguishable_colors(50);
        plotColors = plotColors(4:end,:);
        Colors     = plotColors(1:numel(subjects),:);
        
        figure; hold on;
        
        for p = 1:size(Probs,1)
            
            plot(trials, Probs(p,:), ...
                'LineWidth',2, ...
                'color',Colors(p,:))
            
        end
        
        ylim([0 1.05])
        yticks([0:0.1:1])
        grid on
        
        ylabel('Proportion of significant experiments')
        xlabel('Number of trials')
        
        legend(split(num2str(subjects)),'Location','northeastoutside')
        
        if savePlots
            
            print(gcf, '-painters','-dsvg', ...
                fullfile(datapath, [ matName '_' stimType1 '_' stimType2 '_' aType '_GROUP.svg'] ));
            
            
        end
        
        set(gca, 'XScale', 'log')
        
        if savePlots
            
            print(gcf, '-painters','-dsvg', ...
                fullfile(datapath, [ matName '_' stimType1 '_' stimType2 '_' aType '_GROUP_LOG.svg'] ));
            
            
        end
        
    end
    
end

end