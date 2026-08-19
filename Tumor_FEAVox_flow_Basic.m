function [NodalDisp_vert, stats] = Tumor_FEAVox_flow_Basic(rad,centro,val_HU,vert,vert_out_pth,cpd_data_pth)
% Calcula los desplazamientos de la vertebra "vert" con un tumor de 
% radio "rad" y valor Hounsfield "val_HU" centrado en "centro". Se añade en la parte
% superior e inferior de la vertebra sendos discos intervertebrales donde
% se aplican condiciones de contorno. 
% Esta versión para toracicas
% =========================================================================
% Child functions: None
% Created by: Xavi/Blai (11.2021) ; Modified by: 
% INPUT:
%   - rad = Radio del tumor (en mm).
%   - centro  = Centro del tumor (en mm).  
%               Tamaño: 1x3
%   - val_Hu = Valor en escala Hounsfield para los voxeles en los que se
%              encuentra el tumor.
%   - vert = Vertebra en la que se genra el tumor. Struct con 3 param:
%            Matrix (matriz con valores HU de la vertebra), info 
%            (metadatos del dcom) y utils(opcional, no se usa en esta
%            función).
%            Tamaño: Matrix -> Nvoxels x Nvoxels x Nvoxels  
%   vert_out_pth = Path donde se guarda la vertebra que será usada por 
%                  FEAvox. String.
% OUTPUT:
%   - NodalDisp_vert = Desplazamientos obtenidos para la vertebra en nodos.
%                      Tamaño: Nnodos x 3
%==========================================================================

vert_tumor = Crea_Tumor_Meseta(rad + vert.Info.PixelSpacing(1)*3, rad, centro, val_HU, vert, 0);
vert_Cart = Import_Cartilago_cpd(vert_tumor,cpd_data_pth, 0);



vert_Cart_E = vert_Cart;
vert_Cart_E.Matrix(vert_Cart.Cont==1) = Hounsfield2Young(vert_Cart.Matrix(vert_Cart.Cont==1));
vert_Cart_E.Matrix(vert_Cart.Cont==2) = Hounsfield2Young(vert_Cart.Matrix(vert_Cart.Cont==2),false);
vert_Cart_E.Matrix(vert_Cart.Cont==3) = 42.3e6; %5.8–42.3 MPa DOI: 10.1016/j.jbiomech.2016.02.045


save(vert_out_pth,'-struct','vert_Cart_E')

out_file=vert_out_pth;

Batch_FEAVox_Fracture_1_CC


global BitMap Parameters Results

DensCuttOff=Parameters.Bmp.BmpWindow(1); %El límite inferior de gris

%%%%%%%%%%%%%%%%%%%%%%%%%%% 
[hDisp,hStrain,hStress] = Failure_Post_VoxelsResultsCalculation(1,1,1);

percentile_90 = 0;
%% Calculation of the percentile for the Stress of this dataset so that the singular points do not alter the visualization
for k = 1:6
    prct = abs(prctile(hStress{1}(:,k),99.99))
    if percentile_90 < prct
        percentile_90 = prct;
    end
end
percentile_90

cart_pos=find(vert_Cart.Cont==1 | vert_Cart.Cont==2);
hStress_tmp{1}=zeros(size(hStress{1},1),6);
hStress_tmp{1}(cart_pos,:)=hStress{1}(cart_pos,:);
hStress{1}=hStress_tmp{1};
hVMStress={};
for ii=1:size(hStress,2)
    hVMStress{ii}=sqrt((hStress{ii}(:,1).^2+hStress{ii}(:,2).^2+hStress{ii}(:,3).^2)+...
        -(hStress{ii}(:,1).*hStress{ii}(:,2)+hStress{ii}(:,2).*hStress{ii}(:,3)...
        +hStress{ii}(:,1).*hStress{ii}(:,3))+3*(hStress{ii}(:,4).^2+hStress{ii}(:,5).^2+...
        hStress{ii}(:,6).^2));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NodalDisp=Results.Node(:,1:3);

Ploteo_Bit=Corte_tum(centro,BitMap,vert_Cart);
Vert_cut=Recorte_tum_CPD(centro, BitMap, vert_Cart, true, 0);


hVMStress_scale=hVMStress{1};
% hVMStress_scale(hVMStress_scale>8e6)=8e6;
hVMStress_scale(hVMStress_scale>percentile_90)=percentile_90;

%%--------Visualize the coordinates of the forces for debugging------------
figure('Color', 'w');

% 1. Point cloud extraction from the vertebra matrix
% We use the vert_Cart matrix (or BitMap) and filter the background
pos_vert = find(vert_Cart.Matrix > 0); 
[X_v, Y_v, Z_v] = ind2sub(size(vert_Cart.Matrix), pos_vert);
pc_vertebra = pointCloud([X_v, Y_v, Z_v]);

% Display the geometry
pcshow(pc_vertebra, 'BackgroundColor', [1 1 1]);
hold on;

% 2. Display the force application points
% WARNING: This function does not explicitly receive the force points as input.
% We assume here that they have been saved in the input structure 'vert'
% under the name vert.CPD.Nodes_Neumann).
if isfield(vert_Cart, 'Dot_Forces')
    forces_xyz = vert_Cart.Dot_Forces;
    
    % Plot the points in red
    scatter3(forces_xyz(:,1), forces_xyz(:,2), forces_xyz(:,3), 150, 'r', 'filled');
    
    % Add text labels
    for i = 1:size(forces_xyz, 1)
        text(forces_xyz(i,1), forces_xyz(i,2), forces_xyz(i,3), sprintf('  F%d', i), ...
            'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
    end
elseif isfield(vert_Cart.CPD, 'Nodes_Neumann')
    forces_xyz = vert_Cart.CPD.Nodes_Neumann;
    
    % Plot the points in red
    scatter3(forces_xyz(:,1), forces_xyz(:,2), forces_xyz(:,3), 150, 'r', 'filled');
    
    % Add text labels
    for i = 1:size(forces_xyz, 1)
        text(forces_xyz(i,1), forces_xyz(i,2), forces_xyz(i,3), sprintf('  F%d', i), ...
            'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
    end
else
    disp('Warning: Force coordinates were not found in the vert structure.');
end

% 3. 3D view finishing touches
title('Visualization: Vertebra with tumor and force points');
xlabel('X Axis'); 
ylabel('Y Axis'); 
zlabel('Z Axis');
hold off;
%% -----------------------------------------------------------------------

CR = MarkupPos2Voxel(centro.', vert_Cart.Info);
% PlotsBasicGUI_Failure(BitMap.Matrix,DensCuttOff,hDisp{1},hStrain{1},hStress{1},hVMStress_scale) % With cartilago
%PlotsBasicGUI_Failure(Vert_cut,DensCuttOff,hDisp{1},hStrain{1},hStress{1},hVMStress_scale) % Whithout cartilago and sliced on the tumor
PlotsBasicGUI_Failure(Vert_cut,DensCuttOff,hDisp{1},hStrain{1},hStress{1},hVMStress_scale, CR, rad) % Sphere shape and sliced on the tumor
%PlotsBasicGUI_Failure(Ploteo_Bit,DensCuttOff,hDisp{1},hStrain{1},hStress{1},hVMStress_scale) % Whithout cartilago

% [hSurf_Sup,hSurf_Inf]=Disp_Surf(hDisp);

NodalDisp_vert = NodalDisp(:);
stats = vert_Cart;
% stats = [];
end