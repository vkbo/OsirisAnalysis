
  Osiris Analysis Toolbox
 ******************************************
  MATLAB package for analysing Osiris data
  Current version: 1.0
 

  Developed by:
 =========================
  Veronica K. Berglyd Olsen
  Department of Physics
  University of Oslo
 

  Development History
 =====================
 
  Version 1.0
  - Classes now handle units as normalised by default. Changing units is done when the object is created by using
    standard matlab input pairs. For instance: CH = Charge(<Data object>, 'EB', 'Units', 'SI', 'X1Scale', 'mm');
    This sets class units to SI and the x1-axis (xi-axis) to millimetres.
  - Added plasma density anim and plot.
  - Added Charge class function to return particle selection for scatter plot.

  Version 0.7
  - Added charge conversion calculations to OsirisConfig
  - Changed how Osiris datasets are opened
  - Bug fixes

  Version 0.6
  - Added wavelet functionality

  Version 0.5
  - Initial code with classes for reading OsirisData, OsirisConfig and process Charge, EField and Momentum data.
  - A set of plot functions
 
