clear all
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The data imported here have been preprocessed using GUIs in EEGLab (ICA)
% and BrainVision Analyzer (Visual Artifact Rejection - Triggers handling)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set Fieldtrip 
addpath('MyPath\Toolboxes\fieldtrip-master') % add Fieldtrip to path 
ft_defaults % load Fieldtrip functions
%% Import data
dir=('MyPath\Segmented Data ArtifactFree'); % my path
cd(dir)
sub= ['S01';'S02';'S03';'S05';'S06';'S07';'S08';'S09';'S10';'S11';'S12';'S13';...
     'S14';'S15';'S16';'S17';'S18';'S20';'S21';'S22';'S23']; % S04 had a technical problem and didn't finish the sessions // S19 was an outlier and therefore removed from analysis (see paper)
mark=['corr';'noco']; % NoCorrection / Correction Factor
cond=['F';'G']; % [F = 'Free', referred to Interactive in Publication] [G = 'Guided', referred to Cued in Publication]
subcond=['OP';'UG']; % [OP = 'Opposite', referred to as Complementary in Paper] [UG = 'Uguale -> Same', referred to as Imitative in Paper]
grasp=['up';'do']; %[up = Precision Grasp] [do = Poweer Grasp]

for ii=1:size(sub,1);
    sub_ind=sub(ii,:);
    for kk=1:size(cond,1);
    cond_ind=cond(kk,:);
         for jj=1:size(mark,1);
         mark_ind=mark(jj,:);
            for uu=1:size(subcond,1);
            subcond_ind=subcond(uu,:);
                for ff=1:size(grasp,1);
                grasp_ind=grasp(ff,:);
                    
                      cfg =[];
                      filename=strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Raw files segmented\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'.eeg');
                      cfg.trigger = ft_read_event ('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Raw files segmented\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'.vmrk'); %('C:\Users\Matteo\Documents\My Work\Viviana\data_Viviana\S1_LH.cnt');
                      cfg.dataset=ft_read_header(strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Raw files segmented\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'.vhdr'));
                      savingname1 = strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Induced Evoked\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'_ERP'); 
                      savingname2 = strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Induced Evoked\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'_evoked'); 
                      savingname3 = strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Induced Evoked\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'_induced'); 

                      
                      %% ERPs

                      % Read Markers 
                        cfg =[];
                        cfg.trialdef.prestim = 1;                   % in seconds
                        cfg.trialdef.poststim = 1.5;       
                        cfg.dataset = filename;
                        cfg.trialdef.eventtype = 'Stimulus';
                        cfg  = ft_definetrial(cfg);
                        data = ft_preprocessing(cfg);

                         % preprocess the data
                        cfg = [];
                        cfg.channel    = 'all';     
                        cfg.demean     = 'yes';
                        cfg.baselinewindow  = [-0.2 0];
                        cfg.lpfilter   = 'yes';                              % apply lowpass filter
                        cfg.lpfreq     = 30;                                 % lowpass at 35 Hz.
                        cfg.hpfilter   = 'yes';                              % apply lowpass filter
                        cfg.hpfreq     = 2;                                 % lowpass at 35 Hz.
                        data_f = ft_preprocessing(cfg, data);    

                        cfg = [];
                        avg = ft_timelockanalysis(cfg, data_f);
                        
                        figure;
                        cfg= [];
                        cfg.parameter = 'avg';
                        cfg.xlim = [-0.2 .4];
                        cfg.ylim = [-10 10];
                        cfg.channel = 'FCz';
                        ft_singleplotER(cfg, avg);
                        

                        save(savingname1,'avg')
                      %% Induced Power - Time Frequency
                        
                        % Compute Average

                        cfg = [];
                        cfg.trials = 'all';
                        cfg.keeptrials = 'no';
                        avg_evoked = ft_timelockanalysis(cfg, data);
                        
                        cfg = [];
                        cfg.trials = 'all';
                        cfg.keeptrials = 'yes';
                        avg_induced = ft_timelockanalysis(cfg, data);


                        a = size(avg_induced.trial, 1);
                        bigone=repmat(avg_evoked.avg,[1,1,a]);    
                        evoked = permute(bigone,[3 1 2]);

                        induced = avg_induced.trial - evoked;
                        
                        data_induced = avg_induced;
                        data_induced.trial = induced;
                        
                        % Compute FFT   
                        cfg              = [];
                        cfg.output       = 'pow';
                        cfg.channel      = 'all';
                        cfg.method       = 'mtmconvol';
                        cfg.taper        = 'hanning';
                        cfg.foi          = 2:1:50;                         % analysis 2 to 30 Hz in steps of 2 Hz 
                        cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
                        cfg.toi          = -1:0.05:1.5;  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
                        cfg.pad = 'nextpow2'; 
                        powforall_whole = ft_freqanalysis(cfg, data);
                        powforall_ind = ft_freqanalysis(cfg, data_induced);
                        powforall_evoked = ft_freqanalysis(cfg, avg_evoked);
                        
                        %plot
                                
                        cfg = [];       
                        cfg.baselinetype = 'relchange';
                        cfg.baseline = [-.5 0];
                        cfg.channel = 'FCz'
                        cfg.zlim = [-1 1]
                        cfg.ylim = [1 50];
                        cfg.xlim = [-.5 1];
                        cfg.masknans = 'yes';
                        cfg.interactive = 'yes';
                        cfg.layout = 'EEG1010.lay';
                        figure;
                        ft_singleplotTFR(cfg, powforall_whole);
                        colorbar
                        xlabel('Time (s)');
                        ylabel('Frequency (Hz)');
                        title('Whole')
                        figure;
                        ft_singleplotTFR(cfg, powforall_ind);
                        colorbar
                        xlabel('Time (s)');
                        ylabel('Frequency (Hz)');
                        title('Induced')
                       
                        
                        cfg = [];
                        cfg.baseline     = [-.5 0];
                        cfg.baselinetype = 'relchange';
                        powforall_whole_BL = ft_freqbaseline(cfg, powforall_whole);  
                        
                        cfg = [];
                        cfg.baseline     = [-.5 0];
                        cfg.baselinetype = 'relchange';
                        powforall_induced_BL = ft_freqbaseline(cfg, powforall_ind);
                        
                        powforall_evoked_BL = powforall_whole_BL;
                        powforall_evoked_BL.powspctrm = powforall_whole_BL.powspctrm - powforall_induced_BL.powspctrm;
                        
                        
                        cfg = [];       
                        cfg.channel = 'FCz'
                        cfg.zlim = [-1 1]
                        cfg.ylim = [1 50];
                        cfg.xlim = [-.5 1];
                        cfg.masknans = 'yes';
                        cfg.interactive = 'yes';
                        cfg.layout = 'EEG1010.lay';
                        figure;
                        ft_singleplotTFR(cfg, powforall_evoked_BL);
                        colorbar
                        xlabel('Time (s)');
                        ylabel('Frequency (Hz)');
                        title('Evoked');

                
                save(savingname2, 'powforall_evoked') 
                save(savingname3, 'powforall_ind') 


                end 
            end
         end
    end
end
       
 
