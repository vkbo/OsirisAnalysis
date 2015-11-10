
  Osiris Analysis Toolbox
 ******************************************
  MATLAB package for analysing Osiris data
  Current version: dev1.2
 

  Developed by:
 =========================
  Veronica K. Berglyd Olsen
  Department of Physics
  University of Oslo
 

  Development History
 =====================

  Version 1.2
  - Introduced OsirisType as superclass for Charge, BField, EField, Momentum and Phase
  - Introduced Variables as a class to handle Osiris variable checks and conversions to readable and internal
    formats. This class replaces all the fTranslate... functions from previous version. It also replaces
    the isBeam, isPlasma, isField and isAxis functions.
  - The Variables class can be run independently, but is also accessbile from OsirisData.Translate

  Version 1.1
  - Significant updates to GUI
  - Added plot functions and new classes including a math func interpreter.
  - Updates and bug fixes for OsirisData and OsirisConfig

  Version 1.0
  - Added GUI and updated all plot functions accordingly

  Version 0.7
  - Added charge conversion calculations to OsirisConfig
  - Changed how Osiris datasets are opened
  - Bug fixes

  Version 0.6
  - Added wavelet functionality

  Version 0.5
  - Initial code with classes for reading OsirisData, OsirisConfig and process Charge, EField and Momentum data.
  - A set of plot functions
 
