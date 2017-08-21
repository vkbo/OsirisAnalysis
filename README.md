# OsirisAnalysis

Osiris Analysis Toolbox

MATLAB package for analysing hdf5 data from the PIC code Osiris

**Stable Version:** [1.4.2](https://github.com/Jadzia626/OsirisAnalysis/releases/tag/v1.4.2)<br>
**Development Version:** Dev2.0<br>
Semi-stable on master branch, latest code on develop branch
 
### Developed By

Veronica K. Berglyd Olsen<br>
Department of Physics<br>
University of Oslo

As a part of a PhD thesis project connected to the [AWAKE experiment](http://awake.web.cern.ch/) at CERN.
 
### About Osiris

The simulation software package Osiris is the property of the OSIRIS Consortium (UCLA and IST). It is a parallelised PIC
code for plasma simulations. 

For more information, se the [Osiris Website](https://plasmasim.physics.ucla.edu/codes/osiris).

## Usage

### Configuration

There root directory contains a file named `LocalConfig.m`. This file contains settings for standard output directories
and a Matlab struct of the folders where the user stores Osiris simulation datasets. The folders are only used to avoid
having to enter full paths to load datasets. It is sufficient to just enter the name of the subfolder and OsirisData
will load the first one it finds in these folders.

### Minimal Usage Example

For simple loading of data with OsirisAnalysis, create and OsirisData object and set the path to a dataset. OsirisData
will automatically scan for the input file in the subfolder and check whether data folders exist. If no input file is
found, OsirisData will ask you to choose one.

Example:
```matlab
>> od = OsirisData;
Scanning default data folder(s)
Scanning /scratch/OsirisData
>> od.Path = 'PPE-U10A';
Path is /scratch/OsirisData/PPE-U10A
Config file set: InputDeck.in
```

## Structure

OsirisAnalysis is organised into four levels. The tools can be used at any level depending on your needs.

### Level 1: Core Data Class

**Contains**

* OsirisData Class
* OsirisConfig Class

The first level contains the base data class OsirisData. OsirisData wraps the dataset, and OsirisConfig wraps the Osiris
input file.

This is the minimum usage level of the analysis tool. From here you can extract data as matrices and extract simulation
variables and conversion factors.

### Level 2: Data Type Classes

**Contains**

* BField Class
* EField Class
* Charge Class
* Momentum Class
* Phase Class

These classes take an OsirisData object as input and perform various calculations on them. Most methods return data as
structs, which can be used in the Matlab workspace and plotted directly. These data classes do conversion of units on
the fly and also take the same units as input.

These classes are typically useful to access directly when making plot scripts for more complicated figures for
publications.

### Level 3: Plot Functions

**Contains**

* fPlot... Functions
* fAnim... Functions

These functions output common and pre-formatted standard plots based on the data type classes. They take a minimum set
of variables, and have a number of custom input options. These functions are mainly designed for analysis in order to
speed up the process of analysing the data.

### Level 4: Graphical User Interface

**Contains**

* Analyse2D
* uiTrackDensity

These are graphical user interfaces designed to quickly browse through data and do preliminary data analysis. AnalyseGUI
is simply a wrapper for the standard plot functions, and loads simulation datasets via button clicks and dropdown menus.

The uiTrackDensity tool is designed to study various smaller structures of the beam density data or the fields. This
tool can also output this data for later usage, like tracking the position of a specific peak of a phase of the electric
field. The main benefit of doing this visually is that you can makes sure you tracking is actually tracking the correct
structure.

![Analyse2D](https://raw.githubusercontent.com/wiki/Jadzia626/OsirisAnalysis/Images/Analyse2D.png)

## Core Data Class

### OsirisData

Usage:
```matlab
>> od = OsirisData;
```

This is the main data wrapping class. If search paths have been specified in the `LocalConfig.m` file, these folders
will be scanned and a tree of datasets stored in a struct accessible as `od.DataSets`. OsirisData also creates an
OsirisConfig object that is stored as `od.Config`.

#### Accessing Data

To access the data from the datasets, run the function `od.Data()`.

Example:
```matlab
>> aData = od.Data(0,'DENSITY','Charge','EB');
```

This returns a matrix of the charge density for the electron beam from data dump 0 (start of simulation). The Data
function mainly just forwards the request to the hdf5 library to extract the data requested, but also checks if it
actually exists first. The Osiris data dump has a slightly varying naming scheme, so this class makes it easier to
access these.

**Special case for RAW data**

In the case of requesting RAW data dumps (the macro particles), these are returned as a 8-by-N matrix instead of 7
(for 2D) or 8 (for 3D) individual arrays, which is the way Osiris stores the data.

The columns are as follows:
 1. **x1** - Longitudinal axis.
 2. **x2** - Radial or horizontal axis.
 3. **x3** - Azimuthal or vertical axis. For 2D this one is zero.
 4. **p1** - Longitudinal momentum
 5. **p2** - Radial or horizontal momentum.
 6. **p3** - Azimuthal or vertical momentum.
 7. **ene** - Particle energy
 8. **q** - Particle charge
 9. **tag1** - Particle tag 1
 10. **tag2** - Particle tag 2

#### Data Set Information

There are three functions that will print some simulation information to the workspace.

 * `od.Info()` - Prints general simulation info.
 * `od.PlasmaInfo()` - Prints information about the plasma.
 * `od.BeamInfo('EB')` - Prints infomration about a specific beam.

### OsirisConfig

This class looks for the input file used for the Osiris simulation and tries to extract the simulation variables. It
generates a tree of extracted variables and conversion factors accessible through the OsirisData class as
`od.Config.Variables`. The raw data from the input file is available from `od.Config.Raw`.

The `od.Config` struct also contains four switches:

 * **HasData** is 1 if the folder `MS` (Osiris data folder) exists, otherwise 0.
 * **HasTracks** is 1 if the folder `MS/TRACKS` exists (particle tracking data), otherwise 0.
 * **Completed** is 1 if the simulation is completed by checking if the folder `MS/TIMINGS` exists, otherwise 0.
 * **Consistent** is 1 if all data dump folders have the same number of files, otherwise 0.

### Naming Conventions

OsirisAnalysis tries to translate the names of the species in the input file to a specific naming scheme that it uses
internally. Best practice is to use this naming scheme in the input file in the first place as the flexibility of the
code has not been tested. The naming convention is as follows:

**Beam Particle Species**

Beams are named in camel case as species name followed by "Beam". Example: ElectronBeam, ProtonBeam, IonBeam.

**Plasma Particle Species**

Plasma is named in camel case with "Plasma" followed by species name. Example: PlasmaElectrons, PlasmaIons.

## Data Type Classes

All classes have a similar constructor, but different methods for processing data. They all take an OsirisData object as
first input, and species type as second if relevant. These are the obly required inputs.

The object is initiated at data dump 0, but this can be changed by setting the property `Time` to a data dump number.

Optional inputs can be used to set the units to something other than "N", which is simulation, or normalised, units. At
the moment these classes only support SI units. The scale is the defaulting to metres, but can set to for instance &mu;m
or mm. Other units are also available, but not really practical.

Example:
```matlab
oCH = Charge(od, 'EB', 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
oCH.Time = 10;
```

## Classes

The currently available data type classes are:

### BField and EField Classes

These wraps the electric and magnetic field data sets and perform whatever unit conversion desired as well as any x and
y size limits. The only method is currently returning a matrix of the density of the field with the given restrictions.

### Charge Class

***not finished***
