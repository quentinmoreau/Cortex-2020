dir=('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV');
cd(dir)
sub= ['S01';'S02';'S03';'S04';'S05';'S06';'S07';'S08';'S09';'S10';'S11';'S12';'S13';'S14';'S15';'S16';'S17';'S18';'S20';'S21';'S22';'S23']; %
mark=['corr';'noco'];
cond=['F';'G'];
subcond=['OP';'UG'];
grasp=['up';'do'];

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
                      savingname= strcat('C:\Users\Matteo\Documents\My Work\EEG-Joint Action\Segmented data BV\Induced Connectivity\',sub_ind,'_',mark_ind,'_',cond_ind,'_',subcond_ind,'_',grasp_ind,'_conn'); 

                      cfg.layout = 'EEG1010.lay';
                      
                                       % Markers 
                        cfg =[];
                        cfg.trialdef.prestim = 1;                   % in seconds
                        cfg.trialdef.poststim = 1.5;       
                        cfg.dataset = filename;
                        cfg.trialdef.eventtype = 'Stimulus';
                        cfg  = ft_definetrial(cfg);
                        data = ft_preprocessing(cfg);
                        
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
                        
                        load standard_BEM.mat
                        elec = ft_read_sens('standard_1020.elc'); 
                        
                        
                        % Compute Grid
                        cfg                 = [];
                        cfg.elec            = elec;
                        cfg.headmodel       = vol;
                        cfg.grid.resolution = 10;
                        cfg.grid.unit       = 'mm';
                        cfg.inwardshift     = -1.5;
                        grid                = ft_prepare_sourcemodel(cfg);
                  

                        fr_seed_pos = [0  -10  80]; %% fronto-central 
                        ot_seed_pos = [40 -80  -10]; %% right lotc
                       
                        cfg=[];
                        cfg.method='lcmv';
                        cfg.grid=grid;
                        cfg.vol=vol;
                        cfg.elec = elec;
                        cfg.lcmv.keepfilter='yes';
                        cfg.channel = data.label;
                        cfg.keepleadfield = 'yes';
                        cfg.lcmv.keepfilter = 'yes';
                        cfg.lcmv.projectmom = 'yes';
                        cfg.lcmv.lambda = '10%';
                        cfg.grid.units = 'mm';

                        source=ft_sourceanalysis(cfg, data_induced);
                        
                        cfg = [];
                        cfg.channel =  {'all', '-LM', '-HEOG'};
                        data_eeg = ft_selectdata(cfg, data_induced);

                        virtualchannel_raw = [];
                        virtualchannel_raw.label{1, 1} = 'fronto-central';
                        virtualchannel_raw.label{2, 1} = 'right occipito temporal';
                        j = size(data_eeg.trialinfo, 1)
                        virtualchannel_raw.time = data_eeg.time;
                        x =  1250;
                        c = 2;
                        virtualchannel_raw.trial = zeros(j, 2, 1250)
                        for i = 1:j
                        virtualchannel_raw.trial(i, 1, :) = cell2mat(source.avg.filter(3923)) * squeeze(data_eeg.trial(i,:, :));
                        virtualchannel_raw.trial(i, 2, :) = cell2mat(source.avg.filter(1392)) * squeeze(data_eeg.trial(i,:, :));
                        end
                                            
                        
                        cfg = [];
                        cfg.preproc.demean = 'yes';
                        cfg.preproc.baselinewindow = [-0.6 -0.1];
                        virtualchannel_avg = ft_timelockanalysis(cfg, virtualchannel_raw);
                        
                       
                        cfg              = [];
                        cfg.output = 'powandcsd';
                        cfg.channel      = 'all';
                        cfg.method       = 'mtmconvol';
                        cfg.taper        = 'hanning';
                        cfg.foi          = 2:1:50;                         % analysis 2 to 30 Hz in steps of 2 Hz 
                        cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
                        cfg.toi          = -1:0.05:1.5;  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
                        cfg.pad = 'nextpow2'; 

                        virtualchannel_tf = ft_freqanalysis(cfg, virtualchannel_raw);

                        cfg = [];
                        cfg.method = 'plv';
                        cfg.complex = 'absimag';
                        plv = ft_connectivityanalysis(cfg, virtualchannel_tf);
                        
                        figure;
                        imagesc(plv.time, plv.freq, squeeze(plv.plvspctrm(1, 1:30, :)));
                        colorbar
                        axis xy


                        save(savingname, 'virtualchannel_raw', 'virtualchannel_avg', 'virtualchannel_tf', 'plv');

                        
                end
            end
         end
    end
end