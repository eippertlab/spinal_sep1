% Author: Birgit Nierula
% nierula@cbs.mpg.de

function esg_prepro_loop4(inspect_subjects, srmr_nr)

if srmr_nr == 1
    subj_inspect = {
        'sub-004' 'median' '2' 'S8'; % S8 noisy over whole block --> removed
        'sub-004' 'tibial' '3' 'S8'; % S8 noisy over whole block --> removed
        'sub-004' 'tibial' '4' 'S8'; % S8 noisy over whole block --> removed
        'sub-009'  'median' '4' 'S8'; % S8 is very noisy
        'sub-016' 'median' '' 'S4'; % S4 quite noisy!
        'sub-029' 'median' '3' 'L4';  % peak at 417 Hz, exclude channel L4
        'sub-029' 'median' '4' 'L4';  % exclude channel L4
        'sub-029' 'tibial' '3' 'L4';
        'sub-034' 'tibial' '4' 'S34';
        };
    
    
elseif srmr_nr == 2
    subj_inspect = {
        'sub-004' 'tib_mixed' '1' 'S33' % spectrum of S33 completely off
        'sub-004' 'tib_mixed' '1' 'L4' % spectrum of L4 completely off
        'sub-007' 'tib_mixed' '1' 'S4' % S4 is very noisy
        'sub-014' 'med_mixed' '1' 'Iz' % Iz very noisy!!
        'sub-022' 'tib_digits' '4' 'S34' % bad channel - spectrum completely off troughout the block
        'sub-022' 'tib_digits' '4' 'S36' % bad channel - spectrum completely off at the end of the block
        'sub-022' 'tib_mixed' '1' 'S31' % bad channel - spectrum completely off
        'sub-022' 'tib_mixed' '1' 'S34' % bad channel - spectrum completely off
        };
end


% inpect suspicious subjects
if inspect_subjects
    % check channels
    for ii = 1:length(subj_inspect)
        selected_subjects(ii) = str2num(subj_inspect{ii, 1}(6:7));
    end
    
    for isubject = unique(selected_subjects)
        for icondition = conditions
            [cond_info] = get_conditionInfo(icondition, srmr_nr);
            nblocks = cond_info.nblocks;
            for iblock = 1:nblocks
                close all
                esg_prepro_loop4_check(isubject, icondition, iblock, srmr_nr)
            end
        end
    end
end


% save info about bad channels 
if ~inspect_subjects
    % save for each participant which channels to remove
    tmp = {subj_inspect{:, 1}};
    for ii = 1:length(subj_inspect)
        subj_withbadchans(ii) = str2num(tmp{ii}(6:7));
    end
    
    if srmr_nr == 1
        n_subjects = 36;
    elseif srmr_nr == 2
        n_subjects = 24;
    end
    
    for isubj = 1:n_subjects
        idx = find(subj_withbadchans == isubj);
        if ~isempty(idx)
            for ii = 1:length(idx)
                bad_channels{ii} = subj_inspect{idx(ii), 4};
            end
            bad_channels = unique(bad_channels);
        else
            bad_channels = [];
        end
        
        subject_id = sprintf('sub-%03i', isubj);
        save_path = [getenv('ESGDIR') subject_id '/'];
        fpath = [save_path 'artifacts.mat'];
        if exist(fpath, 'file')
            save(fpath, 'bad_channels', '-append')
        else
            save(fpath, 'bad_channels')
        end
        
    end
end
