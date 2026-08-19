# Predicting Structural Failure in Tumor-Affected Thoracic Vertebrae

**Status:** 🚧 *Repository Under Construction. Full codebase is currently being migrated from the UPV laboratory servers and will be fully available by mid-September 2026.* 🚧

## Overview
A MATLAB pipeline for the longitudinal segmentation of CT scans and the biomechanical prediction of structural failure in thoracic vertebrae affected by metastatic tumors. 

This repository contains the codebase developed and modified during a research internship at the Institute of Mechanics, Materials, and Biomechanics (I2MB) at the Universitat Politècnica de València (UPV). By combining patient-specific CT scan data, Coherent Point Drift (CPD) transformations, Cartesian Grid Finite Element Method (cgFEM), and Random Forest classification, this pipeline automates the prediction of structural bone failure.

---

## ⚠️ Important Usage Note: Preliminary Manual Data Entry
Please note that in this current iteration of the pipeline, **several key anatomical features must be extracted manually** prior to running the automated scripts. Users applying the prediction pipeline to new patient datasets will need to use 3D Slicer (or a similar DICOM viewer) to manually measure and record:
*   The bounds and centroid coordinates of the tumors.
*   The Housnfield Units within the tumors.

Additionaly, the adaptation pipeline requires the manual generation of the reference patient in Tumor_FEAVox_flow_Main_CPD, 
*   The exact reference nodes for Coherent Point Drift (CPD) alignment.
*   The limits of the cartilago frame
*   The center position to calculate the central Vertebral Body Height (VBH).

Once this preliminary data is collected, the following MATLAB scripts can successfully automate the mechanical and predictive analysis.

---

## Repository Architecture

### 1. Offline Preparation (Reference Patient)

#### `GetCoordinatesToTransform.m`
* **Input:** `.osim` (OpenSim musculoskeletal model)
* **Process:** Parses the model to extract the raw spatial coordinates for muscle and rib force application points.
* **Output:** `Workspace Variables` (Raw 3D coordinate arrays)

#### `GetCoordinatesOfRibs.m`
* **Input:** `Workspace Variables` (Raw rib coordinates), `.txt` (CPD-derived reference coordinates)
* **Process:** Applies the Kabsch algorithm to optimally align and transform the raw ribcage coordinates to the patient-specific vertebra.
* **Output:** `.txt` (Transformed rib contact coordinates)
* ⚠️ This algorithm is incorrect for our case study but put here for other possible use.

#### `OpenSim_Reader_Directions.m`
* **Input:** `.osim` (OpenSim model)
* **Process:** Computes normalized force orientation vectors based on the anatomical insertion and origin points in the model.
* **Output:** `.txt` (Force direction vectors)

### 2. Online Analysis (Patient-Specific Workflow)

#### `Main_Matrix_Generator.m`
* **Input:** `.dcm` (Raw patient DICOM slices), User inputs (Date and Tumor parameters)
* **Process:** Acts as the primary execution script for the adapted structural analysis, orchestrating the file directory paths and calling the semantic segmentation executable.
* **Output:** `.mat` (Homogeneous geometric matrices for the specific bone)

#### `Get_patient_height.m`
* **Input:** `.txt` or User Input (Manually measured VBH)
* **Process:** Uses Ordinary Least Squares (OLS) regression coefficients to estimate the patient's full body height.
* **Output:** `Numeric Value` (Estimated patient height in cm)

#### `Extraction_Of_Forces_Reactions.m`
* **Input:** `.txt` (Reference force values), `.mat` (Trained regression ensemble), `Numeric Value` (Patient height)
* **Process:** Retrieves patient morphometrics and applies the regression model to scale and output patient-specific load magnitudes.
* **Output:** `.txt` (Patient-specific force loads)

#### `Patient_Specific_Boundary_Cdts.m`
* **Input:** `.txt` (Predicted force loads and orientations)
* **Process:** Integrates the patient's specific force values and vectors into the boundary condition arrays required for finite element analysis.
* **Output:** `.mat` (Boundary condition structures)

### 3. Core cgFEM Analysis [Modified I2MB Scripts]
*Note: The following core scripts were originally developed by researchers at the I2MB lab. During this project, they were significantly refactored into dynamic functions to handle patient-specific inputs and enable automated batch processing.*

#### `Main_CPD_Vertebrae_Generator.m`
* **Input:** `int` (from 1 to 12 for the vertebra to be analyzed), `string` (Path of the original .mat reference vertebra), `string` (Path of the new .mat reference vertebra)
* **Process:** To be applied with the same patient for both inputs to change the reference vertebra. It allows to check if a vertebra is oriented in our standard coordinate system then rotate it in case. It allows to get and change the coordinates of the force nodes, rib joints and center of the surfaces manually. It allows to resize the frame defining the surface of the cartilago.
* **Output:** `.mat` of the reference vertebra.
* 
#### `Tumor_FEAVox_flow_Main_CPD.m`
* **Input:** `.mat` (Patient's specific vertebra), `Numeric Values` (Vertebra level, Tumor radius, Tumor center coordinates, and Tumor HU value)
* **Process:** Automatically loads the corresponding healthy reference vertebra, executes the Coherent Point Drift (CPD) registration to map the new vertebra's geometry, maps the intervertebral cartilages, and converts local tumor coordinates to the global reference frame.
* **Output:** `.mat` (Saved CPD transformation data and updated patient vertebra structure).

#### `Tumor_FEAVox_flow_Basic.m`
* **Input:** `Workspace Variables` (Tumor parameters and the CPD-registered vertebra structure from the previous function), `String` (File paths for outputs)
* **Process:** Integrates the tumor into the mesh, assigns Young's Modulus values based on HU density, and executes the core cgFEM elastostatic solver (`Batch_FEAVox_Fracture_1_CC`). It calculates the 99.99th percentile of the resulting stress field to dynamically filter out numerical singularities before computing the von Mises stress.
* **Output:** `Workspace Array` (Nodal displacements and stress/strain arrays), `GUI Interface` (Triggers the 3D visualization tools)

#### `PredictionToracic.m`
* **Input:** `Numeric Value` (Predicted patient height, provided by `Extraction_Of_Forces_Reactions.m`)
* **Process:** Calculates the patient's estimated mean weight based on the input height, then runs the trained bagged-trees regression model to compute the magnitudes for all pre-entered thoracic muscles.
* **Output:** `.txt` (Text file containing the predicted force value for each specified muscle)

#### `Prob_NeumannOnNodes_CPD.m`
* **Input:** `.txt` (Orientation vectors), `.mat` (cgFEM mesh matrices)
* **Process:** Adapts the thoracic spine mechanical pipeline to read custom orientation vectors and apply Neumann boundary conditions (point loads) using Rodrigues' rotation formula.
* **Output:** `.mat` (Updated finite element boundary condition matrices)

### 4. Machine Learning (Fracture Prediction)

#### `Fracture_Risk_Prediction.m`
* **Input:** `Workspace Variables` / `.mat` (Combined feature database including mechanical stress fields, VBH, HU values, tumor growth rates, and true fracture status)
* **Process:** Combines all the extracted features to train the Random Forest classification ensemble. It utilizes Leave-One-Out Cross-Validation (LOOCV) to robustly test the algorithm and evaluate its predictive capabilities.
* **Output:** `Console Output & .fig` (Performance metrics including the F1-score, the ROC curve / AUC, the OOB feature importance chart, and the confusion matrices)

### 5. Graphical User Interface (GUI)

#### `PlotsBasicGUI_Failure.mlapp`
* **Input:** `.mat` (Final stress/strain fields and tumor centroid coordinates)
* **Process:** Renders an interactive 3D interface for clinicians to view the results. 
* **Output:** `GUI Interface` (Displays voxel-level displacements, strain, von Mises stress, and the custom "Sphere on Tumor" localized distribution)

---

## Technologies Used
* **MATLAB** (App Designer, Statistics and Machine Learning Toolbox)
* **OpenSim API** (for musculoskeletal modeling)

## Author & Acknowledgements
**Rovatiana Randrianarison**  
*ENSTA Paris (Class of 2027)*  

*Special thanks to the I2MB laboratory (Universitat Politècnica de València) and my supervising professors for providing the foundational cgFEM framework and guidance throughout this research.*
