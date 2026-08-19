%-----------------------------Main_Matrix_Generator-----------------------------%
% For each of the 6 patients WITHOUT fracture : 
% -- 1. Applies the corrected segmentation.
% -- 2. A loop for each vertebrae n°v (WARNING : some patients do not have all of them): 
% ----- a. Running Dicom_mat_homog(tmp_dicom,patient_folder,v)
% ----- b. Using Nodes_Fores_Puntuals_Tv (It is more practial to change the Nodes_Fores_Puntuals file)
% ----- c. Running Tumor_FEAVox_flow_Main_CPD(Vert_new, v, rad, centro, HU)

% Read once outside the loops
data = readtable("D:\rrandri\Codigo_segmentacion\Patients_List.txt", 'ReadVariableNames', false);
data.Properties.VariableNames = {'Num_CT', 'Patient', 'Date'};

% Convert immediately to string arrays for faster comparison later
pt = string(data.Patient); 
numCT = data.Num_CT;
date = string(data.Date);
N_pat = 10;
base_matrix_path = "D:\rrandri\FEAVox_Simple\Patients_matrixes";
num_dates = [16, 7, 14, 17, 18, 9, 7];
first_date = [16, 17, 24, 38, 55, 72, 81];
i = 1;

%% Main Loop on all the patients WITHOUT fracture to set the folders
    %Can be ommented if already run once on all available data
for p = 4:N_pat

    % Creating a folder to store all this patient's information
    p_foldername = "Patient_NOFRAC_" + int2str(p);
    full_p_path = fullfile(base_matrix_path, p_foldername);

    if ~exist(full_p_path, 'dir')
        state = mkdir(full_p_path);
        if ~state
            error('Could not create or open the file: %s', p_foldername);
        end
    end
    p_ind = p - 3;

    for d = 1:num_dates(p_ind)
        %tic;
        %% 1. Applying the segmentation on this given patient at all their dates
        filename = fullfile(base_matrix_path, p_foldername, "cmd_line.txt");
        fileID = fopen(filename, 'w');

        if i <= length(numCT) && i == numCT(i)
            path_cmd = "D:\rrandri\Codigo_segmentacion";
            fprintf(fileID, '%s\n', path_cmd);
            fprintf(fileID, '%s\n', int2str(i));
        end
        fclose(fileID); 

        path_program = '"D:\rrandri\FEAVox_Simple\start_cv_Demo_exe_Corrected.exe"';

        % We want the program not to run if the dicom files already exist and are the
        % updated ones
        % 1. Check if the dicoms were updated after the receiving of the new version
        % of segmentation (1/06/2026) one is enough because they are
        % modified simultaneously
        ref_file = "D:\rrandri\Codigo_segmentacion\Vertebrae\" + pt(i) +" "+ date(i) + "\tmp\5_Vert_dicom\" + "Paciente_"+ pt(i) +" "+ date(i) +"_0_20";
        date_limit = datetime(2026, 06, 01); 
        % 2. Get info on the file
        file_info = dir(ref_file);
        % 3. Check existence and compare dates
        if ~isempty(file_info)
            date_modif = datetime(file_info(1).datenum, 'ConvertFrom', 'datenum');            
            % If the last modification was before the limit
            if date_modif < date_limit

                %% 1. Applying the segmentation on this given patient at all their dates
                filename = fullfile(base_matrix_path, p_foldername, "cmd_line.txt");
                fileID = fopen(filename, 'w');

                if i <= length(numCT) && i == numCT(i)
                    path_cmd = "D:\rrandri\Codigo_segmentacion";
                    fprintf(fileID, '%s\n', path_cmd);
                    fprintf(fileID, '%s\n', int2str(i));
                end
                fclose(fileID); 

                % Execution
                % system(path_program + "<" + filename); % UNCOMMENT HERE IF NEW SCANS TO ANALYZE
            else
                disp('Not executed : segmentation already performed avec algorithm update.');
            end
        else
            disp('Error : The specified reference file for date cannot be found.');
        end

        %% 2. a) Homogeneization
        p_subfoldername = "Patient_NOFRAC_" + int2str(p) + "_" + date(i);
        new_path = fullfile(base_matrix_path + "\"+ p_foldername, p_subfoldername);

        if ~exist(new_path, 'dir')
            state = mkdir(new_path);
            if ~state
                error('Could not create or open the file: %s', p_subfoldername);
            end
        end

        % Directory of original data
        tmp_path = "D:\rrandri\Codigo_segmentacion\Vertebrae\" + pt(i) +" "+ date(i) + "\tmp\5_Vert_dicom";

        %% For all thoracic vertebrae 
        for v = 8:19
            vert_filename = "Paciente_" + pt(i)+" "+ date(i) + "_0_" + int2str(v);
            vert_t_filename = "Paciente_" + pt(i) +" "+ date(i) + "_0_" + num2vertebra(v);

            %It is possible that this patient does not present some vertebrae.
            % Or that the file has already been generated
            if exist(fullfile(tmp_path, vert_filename), 'dir') && ~exist(fullfile(new_path, vert_t_filename), 'dir')
                Dicom_mat_homog(tmp_path, new_path, v); % UNCOMMENT HERE
                % IF NEW DICOM TO CONVERT INTO NIFTII.
            end
        end
        %toc;
        i = i + 1; 
    end
end

%% 2. b&c) Display the user interface for a chosen patient, date, vertebra and tumor
patient = 8; % From 1 to 10
d = 13; % For each patient there are [16, 7, 14, 17, 18, 9, 7]
vert = 5; % From 1 to 12
rad = 15;
val_HU = 800;
centro = [88, 70, 65];

p_subfoldername = "Patient_NOFRAC_" + patient;
p_subsubfoldername = fullfile(p_subfoldername + "_" + date(first_date(patient - 3)+d-1));
Vert_new = load(fullfile(base_matrix_path, p_subfoldername,p_subsubfoldername, "\Paciente_" + pt(first_date(patient - 3)+d-1) + " " + date(first_date(patient - 3)+d-1) + "_0_T" + int2str(vert))) ;%+ ".mat");

%Vert_new = "D:\rrandri\FEAVox_Simple\Patients_matrixes\Patient_NOFRAC_7\Patient_NOFRAC_7_20151130\Paciente_MetNOFrac_007 20151130_0_T5.mat";

%% Give the node forces and the surface forces corresponding to this specific patient and vertebra
spec_node_force_pth = "D:\rrandri\FEAVox_Simple\Patients_matrixes\Patient_NOFRAC_"+int2str(patient)+"\NodeForces\Nodes_Forces_Puntuals_T"+int2str(vert)+".txt";
%This means we would have to modify the Data extracting code so it fits the path
node_force_pth="D:\rrandri\FEAVox_Simple\Samples\100_LumbarLoads_Basic\Nodes_Forces_Puntuals.txt";
[status, message] = copyfile(spec_node_force_pth, node_force_pth, 'f');
if ~status
    error('Error when rewritting the Nodes file : %s', message);
end

spec_load_pth = "D:\rrandri\FEAVox_Simple\Patients_matrixes\Patient_NOFRAC_"+int2str(patient)+"\Loads\113_JointReaction_ReactionLoads_disctinct_Total_T"+int2str(vert)+".txt";
%This means we would have to modify the Data extracting code so it fits the path
load_pth="D:\rrandri\FEAVox_Simple\Samples\100_LumbarLoads_Basic\Surface_Forces.txt";
[status, message] = copyfile(spec_load_pth, load_pth, 'f');
if ~status
    error('Error when rewritting the Loads file : %s', message);
end

%% Run the interface for this specific case
Tumor_FEAVox_flow_Main_CPD(Vert_new, vert, rad, centro, val_HU)