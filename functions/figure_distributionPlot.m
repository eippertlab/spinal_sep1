function figure_distributionPlot(condition, ...
    srmr_nr, target_chan, selected_subjects)

%% set variables
loadpath_ga = getenv('GADIR');

% get condition info
[cond_info] = get_conditionInfo(condition, srmr_nr);
cond_name = cond_info.cond_name;

% load data
fname = ['stats_ind_snr_' cond_name '.mat'];
load([loadpath_ga fname]) 

% load target channel
data1 = [snr_ind.(target_chan)]; 
% load cca channel
data2 = [snr_ind.esg_cca];
datasets = {snr_ind.(target_chan), snr_ind.esg_cca}; 


figXLim      = [0.5 2.5];
figYLim      = [-1 200];
figPosition  = [0 0 300 600];
figColor     = [1 1 1];
figXLabel    = [];
figYLabel    = 'SNR';

positions1   = 1;
positions2   = 2;
colors = {[1 0 0] [0 0 1] [0.8 0.8 0.8]};


%% figure
figure; hold on; set(gcf, 'color', figColor , 'position', figPosition); 


h=boxplot(data1, 'positions',positions1(1), 'Colors',colors{1} ,'Widths', [0.1] ,'Symbol','.r');
g=boxplot(data2, 'positions', positions2(1) , 'Colors', colors{2},'Widths', [0.1] ,'Symbol','.r');
set(h,'LineWidth',2 )
set(g,'LineWidth', 2)

distributionPlot(data1','distWidth',0.3,'showMM',0, 'color', colors{1}, 'widthDiv',[2 1], 'histOri','left', 'xValues', positions1-0.2)
distributionPlot(data2','distWidth',0.3,'showMM',0, 'color', colors{2}, 'widthDiv',[2 2], 'histOri','right', 'xValues', positions2 + 0.2)

positions = {positions1(1)+0.07 positions2(1)-0.07};
counter   = 0;

for p = [1]
    for j = 1:length(datasets{1})

        if j == selected_subjects(1) %red

            line([positions{p} positions{p+1}], [datasets{p}(j) datasets{p+1}(j)], ...
                'color', [1 0 0], 'linewidth', 1);

        elseif j == selected_subjects(2) %green
            line([positions{p} positions{p+1}], [datasets{p}(j) datasets{p+1}(j)], ...
                'color', [0 1 0], 'linewidth', 1);

        elseif j == selected_subjects(3) %blue

            line([positions{p} positions{p+1}], [datasets{p}(j) datasets{p+1}(j)], ...
                'color', [0 0 1], 'linewidth', 1);



        else

            line([positions{p} positions{p+1}], [datasets{p}(j) datasets{p+1}(j)], ...
                'color', colors{3}, 'linewidth', 1);

        end
    end
end


xticks([positions1(1) positions2])
set(gca,'xticklabel',[],...
    'GridAlpha',0.5, 'xlim', figXLim, 'ylim', figYLim)
xlabel(figXLabel)
ylabel(figYLabel)

box off

% save figure
fname = [ cond_name '_distributionPlot' ];
print([getenv('FIGUREPATH') fname], '-dsvg', '-painters') 
