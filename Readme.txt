
  Osiris Analysis Toolbox
 ******************************************
  MATLAB package for analysing Osiris data
  Current version: 1.2.1
 

  Developed by:
 =========================
  Veronica K. Berglyd Olsen
  Department of Physics
  University of Oslo
 

  Development History
 =====================

  Version 1.2.1
  - Bug fixes
  - More code cleanup. Including removing fExtractEQ that has been replaced by class MathFunc.

  Version 1.2
  - Introduced OsirisType as superclass for Charge, BField, EField, Momentum and Phase.
  - Introduced Variables as a class to handle Osiris variable checks and conversions to readable and internal
    formats. This class replaces all the fTranslate... functions from previous version. It also replaces
    the isBeam, isPlasma, isField and isAxis functions.
  - The Variables class can be run independently, but is also accessbile from OsirisData.Translate
  - Removed fStringToDump and merged it into OsirisData. This function needs an OsirisData object anyway, so
    no point having an independant function.
  - Merged function fPlasmaPosition into OsirisType. It too needs an OsirisData object, but fits better with
    OsirisType because ut also depends on the current time dump.
  - OsirisData now accepts data files with non-standard species names. In theory. Not tested.

  Version 1.1
  - Significant updates to GUI
  - Added plot functions and new classes including a MathFunc interpreter.
  - Updates and bug fixes for OsirisData and OsirisConfig

  Version 1.0
  - Classes now handle units as normalised by default. Changing units is done when the object is created by using
    standard matlab input pairs. For instance: CH = Charge(<Data object>, 'EB', 'Units', 'SI', 'X1Scale', 'mm');
    This sets class units to SI and the x1-axis (xi-axis) to millimetres.
  - Added plasma density anim and plot.
  - Added Charge class function to return particle selection for scatter plot.
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
 
