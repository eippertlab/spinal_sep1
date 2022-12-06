% Author: Birgit Nierula
% nierula@cbs.mpg.de

function  eeg_prepro_loop7_2_allBlocks(subject, sasica_comps)

%% loop 7: save ICA components
% define variables
subject_id = sprintf('sub-%03i', subject); 
analysis_path = [getenv('ANADIR') subject_id '/eeg/prepro/'];
save_path = [getenv('EEGDIR') subject_id '/'];


% save marked components
fname1 = [analysis_path 'allConditions_ICAcomps_marked_for_rejection.mat'];
fname2 = [save_path 'allConditions_ICAcomps_marked_for_rejection.mat'];


disp('##### save components #####')
disp('Components automatically selected with SASICA (this is NOT your SASICA selection!!): ')
sasica_comps

disp('### Enter final components: ')
marked_comps_SASICA.eye = input('Eye components in []:   ');
marked_comps_SASICA.heart = input('Heart components in []:   ');
marked_comps_SASICA.other = input('Other components in []:   ');
marked_comps_SASICA.all = unique([marked_comps_SASICA.eye marked_comps_SASICA.heart marked_comps_SASICA.other]);


% display final selection
fprintf('\n\n\n')
disp('copy to lab book:')
disp('###################################')
disp('##### Identified components  #####')
disp('##### eye:')
marked_comps_SASICA.eye
disp('##### heart:')
marked_comps_SASICA.heart
disp('##### other:')
marked_comps_SASICA.other
disp('###################################')

   
if ~exist(fname)
    save(fname1, 'marked_comps_SASICA')
    save(fname2, 'marked_comps_SASICA')
else
    save(fname1, 'marked_comps_SASICA', '-append')
    save(fname2, 'marked_comps_SASICA', '-append')
end


end
