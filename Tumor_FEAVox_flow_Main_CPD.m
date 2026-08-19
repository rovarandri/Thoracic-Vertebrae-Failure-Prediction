
function Tumor_FEAVox_flow_Main_CPD(Vert_new, v, rad, centro, val_HU)

%Vert_new=load('D:\rrandri\Vertebrae_original_prueba\Paciente_MetSIFrac_003 20160922_0_T5.mat');
Vert_org=load("D:\rrandri\FEAVox_Simple\Samples\100_LumbarLoads_Basic\CPD_Surface\CPD_Vertebrae_Generator\Vert_ref_T" + int2str(v) + ".mat");


vert_out_pth = ['D:/rrandri/FEAVox_Simple/Samples/100_LumbarLoads_Basic/ImageFiles/Vert_new_cart_T', int2str(v),'.mat']; % + ".mat";
cpd_data_pth = ['D:/rrandri/FEAVox_Simple/Samples/100_LumbarLoads_Basic/ImageFiles/CPD_data_cart_T' , int2str(v),'.mat']; % + ".mat";



[Vert_data,CPD_data]=CPD_New_Vertebra_V2(Vert_new,Vert_org);

%%
[~, CPD_data] = Crea_Cartilago_cpd_V2(Vert_data,CPD_data);

save(cpd_data_pth,'-struct','CPD_data')
save('D:/rrandri/FEAVox_Simple/Samples/100_LumbarLoads_Basic/ImageFiles/CPD_data_path.mat','cpd_data_pth')

%%
Vert_new=limpiarSuperficieHU(Vert_new);
Vert_new.Matrix(Vert_new.Matrix<0)=0;
Vert_new.Cont=double(Vert_new.Matrix~=0);

centro = Local2GlobalPos(centro.', Vert_new.Info).';

NodalDisp_vert = Tumor_FEAVox_flow_Basic(rad,centro,val_HU,Vert_new,vert_out_pth,cpd_data_pth);

% Vert_new=load('D:\rrandri\Vertebrae_original_prueba\Paciente_MetSIFrac_003 20160922_0_T5.mat');
% Vert_org=load('D:\rrandri\FEAVox_Simple\Samples\100_LumbarLoads_Basic\CPD_Surface\CPD_Vertebrae_Generator/Vert_ref_T5.mat');
% 
% 
% vert_out_pth = 'D:/rrandri/FEAVox_Simple/Samples/100_LumbarLoads_Basic/ImageFiles/Vert_new_cart_T5.mat';
% cpd_data_pth = 'D:/rrandri/FEAVox_Simple/Samples/100_LumbarLoads_Basic/ImageFiles/CPD_data_cart_T5.mat';
% 
% 
% 
% [Vert_data,CPD_data]=CPD_New_Vertebra_V2(Vert_new,Vert_org);
% 
% %%
% [~, CPD_data] = Crea_Cartilago_cpd_V2(Vert_data,CPD_data);
% 
% save(cpd_data_pth,'-struct','CPD_data')
% save('D:/rrandri/FEAVox_Simple/Samples/100_LumbarLoads_Basic/ImageFiles/CPD_data_path.mat','cpd_data_pth')
% 
% %%
% Vert_new=limpiarSuperficieHU(Vert_new);
% Vert_new.Matrix(Vert_new.Matrix<0)=0;
% Vert_new.Cont=double(Vert_new.Matrix~=0);
% 
% rad = 1;
% val_HU = 5000;
% centro = [88, 70, 65];
% centro = Local2GlobalPos(centro.', Vert_new.Info).';
% 
% NodalDisp_vert = Tumor_FEAVox_flow_Basic(rad,centro,val_HU,Vert_new,vert_out_pth,cpd_data_pth);