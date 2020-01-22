% % % % % % % % % %load MRI
load C:\Users\Matteo\Documents\MATLAB\headmodel\standard_mri.mat
mri = ft_volumereslice([], mri); 
% % % % % % % % % % %Load atlasaal = ft_read_atlas('C:\Users\Matteo\Documents\MATLAB\fieldtrip-20150113\template\atlas\aal\ROI_MNI_V4.nii');

sub= ['S01';'S02';'S03';'S05';'S06';'S07';'S08';'S09';'S10';'S11';'S12';'S13';...
     'S14';'S15';'S16';'S17';'S18';'S20';'S21';'S22';'S23'];
 mark=['corr'];
cond=['F'];
Source_F_corr_Frontal = [];
Source_F_corr_Right_OTC = [];
Source_F_corr_Left_OTC = [];

% subcond=['OP';'UG'];
% grasp=['up';'do'];
for ii=1:size(sub,1);
sub_ind=sub(ii,:);
    for kk=1:size(cond,1);
        cond_ind=cond(kk,:);
        for jj=1:size(mark,1);
        mark_ind=mark(jj,:);
            
            %% LOAD POWER FOR SUBJ
            up1 = load(strcat(sub_ind,'_',mark_ind,'_',cond_ind,'_OP_up_induced_source_thetalpha.mat'));
            up2 = load(strcat(sub_ind,'_',mark_ind,'_',cond_ind,'_UG_up_induced_source_thetalpha.mat'));
            do1 = load(strcat(sub_ind,'_',mark_ind,'_',cond_ind,'_OP_do_induced_source_thetalpha.mat'));
            do2 = load(strcat(sub_ind,'_',mark_ind,'_',cond_ind,'_UG_do_induced_source_thetalpha.mat'));

            cfg = [];
            Subj = ft_sourcegrandaverage(cfg, up1.sourceDiffInt, up2.sourceDiffInt, do1.sourceDiffInt, do2.sourceDiffInt);

            %% define ROI
            ctrl_idx = strmatch('Supp_Motor_Area', aal.tissuelabel);
            PC_idx = strmatch('Paracentral', aal.tissuelabel);
            frt_idx = cat(1,ctrl_idx, PC_idx);
            % temp_idx_L1 = strmatch('Angular_L', aal.tissuelabel);
            temp_idx_L2 = strmatch('Occipital_Inf_L', aal.tissuelabel);
            temp_idx_L3 = strmatch('Occipital_Mid_L', aal.tissuelabel);
            temp_idx_L = cat(1, temp_idx_L2, temp_idx_L3);

            % temp_idx_R1 = strmatch('Angular_R', aal.tissuelabel);
            temp_idx_R2 = strmatch('Occipital_Inf_R', aal.tissuelabel);
            temp_idx_R3 = strmatch('Occipital_Mid_R', aal.tissuelabel);
            temp_idx_R = cat(1, temp_idx_R2, temp_idx_R3);

            % temp_IDX = cat(1, temp_idx_R, temp_idx_L);


            cfg = [];
            cfg.inputcoord = 'mni';
            cfg.atlas = aal;
            cfg.roi = aal.tissuelabel(frt_idx);
            frt1 = ft_volumelookup(cfg, Subj);

            cfg = [];
            cfg.inputcoord = 'mni';
            cfg.atlas = aal;
            cfg.roi = aal.tissuelabel(temp_idx_L);
            temp_L = ft_volumelookup(cfg, Subj);

            cfg = [];
            cfg.inputcoord = 'mni';
            cfg.atlas = aal;
            cfg.roi = aal.tissuelabel(temp_idx_R);
            temp_R = ft_volumelookup(cfg, Subj);


            ROI_frt = frt1(:);
            ROI_num_frt = double(ROI_frt);
            ROI_temp_L = temp_L(:);
            ROI_num_temp_L = double(ROI_temp_L);
            ROI_temp_R = temp_R(:);
            ROI_num_temp_R = double(ROI_temp_R);

            %% get values for each ROI

            frt_val= ROI_num_frt.*Subj.pow;
            frt_val_f = frt_val(find(frt_val~=0));

            val_max_frt = max(frt_val_f);
            val_mean_frt = nanmean(frt_val_f);

            tempL_val= ROI_num_temp_L.*Subj.pow;
            tempL_val_f = tempL_val(find(tempL_val~=0));
            val_max_tempL = max(tempL_val_f);
            val_mean_tempL = nanmean(tempL_val_f);

            tempR_val= ROI_num_temp_R.*Subj.pow;
            tempR_val_f = tempR_val(find(tempR_val~=0));
            val_max_tempR = max(tempR_val_f);
            val_mean_tempR = nanmean(tempR_val_f);
            
            Source_F_corr_Frontal(ii,:) = val_mean_frt;
            Source_F_corr_Right_OTC(ii,:) =  val_mean_tempR;
            Source_F_corr_Left_OTC(ii,:) =  val_mean_tempL;

        end
    end
end
