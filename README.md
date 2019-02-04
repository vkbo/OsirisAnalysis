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

### Note as of October 2018

The development of this package was part of my thesis work, and stopped when I finished using Osiris for simulations.
The code was forked and used to devlop a minimal set of classes for analysing QuickPIC data for my last publication for my thesis. That code is in a separate repository named [QickPICAnalysis](https://github.com/vkbo/QuickPICAnalysis).

This code has been used for two conference papers for [IPAC'15](https://jacowfs.jlab.org/conf/proceedings/IPAC2015/papers/wepwa026.pdf) and [NAPAC'16](http://accelconf.web.cern.ch/AccelConf/napac2016/papers/tua4co03.pdf), and for my [thesis](https://cds.cern.ch/record/2655446?ln=en).
 
### About Osiris

The simulation software package Osiris is the property of the OSIRIS Consortium (UCLA and IST). It is a parallelised PIC
code for plasma simulations. 

For more information, se the [Osiris Website](https://plasmasim.physics.ucla.edu/codes/osiris).

----

# Documentation

Here follows a brief description of the analysis toolbox and some usage examples. For more detailed examples, see the
below this section.

## Configuration

The root directory of the analysis tool contains a file named `LocalConfig.m`. This file contains settings for standard
output directories and a MATLAB struct of the folders where the user stores Osiris simulation datasets. The folders are
only used to avoid having to enter full paths to load datasets as MATLAB does not provide path autocompletion for
function inputs. Instead, the data wrapper object will scan the paths specified in the config file and create a map of
the simulations found there. To load such a simulation, only the name of the data folder needs to be set in the data
wrapper object. The object does also accept a full path.

## Minimal Usage Example

For simple loading of data with OsirisAnalysis, create and OsirisData object and set the path to a dataset. OsirisData
will automatically scan for the input file in the subfolder and check whether data folders exist. If no input file is
found, or multiple possible ones are found, OsirisData will ask you to choose one.

Example:
```matlab
>> od = OsirisData;
Scanning default data folder(s)
Scanning /scratch/OsirisData
>> od.Path = 'PPE-U10A';
Path is /scratch/OsirisData/PPE-U10A
Config file set: InputDeck.in
```

## The Analysis Tool Structure

OsirisAnalysis is organised into four levels. The tools can be used at any level depending on your needs.

### Level 1: Core Data Class

**Contains**

* OsirisData Class
* OsirisConfig Class

The first level contains the base data class OsirisData which wraps the dataset. OsirisConfig is a class automatically
loaded by OsirisData, and wraps and parses the Osiris input file.

This is the minimum usage level of the analysis tool. From here you can extract data as MATLAB matrices and extract
simulation variables and conversion factors to convert Osiris' normalised units to SI units.

**Additional Core Classes**

* MathFunc Class
* Variables Class

The MathFunc class emulates the Osiris built-in function parser. Since Osiris can take density profiles for the various
particle species as mathematical expressions, extracting initial beam parameters can involve solving these equations.
This class provides functionality for the OsirisData class to evaluate these expression in the same way Osiris does.
This is for instance used to calculate beam dimensions, total charge and beam current. Values that are not independently
specified in the input files.

Such information can be viewed by calling `OsirisData.BeamInfo('EB')` for for instance the electron beam.

### Level 2: Data Type Classes

**Contains**

* Density Class
* Field Class
* Charge Class
* Momentum Class
* Phase Class
* Species Class
* UDist Class

These classes take an OsirisData object as input and perform various calculations on them. Most methods return data as
structs, which can be used in the Matlab workspace and plotted directly. These data classes do conversion of units on
the fly and also take the same units as input. They also return properly scaled axes.

These classes are typically useful to access directly when making plot scripts for more complicated figures for
publications.

All these classes are subclasses of one superclass called OsirisType. OsirisType is not intended to be called directly.
It only contains common set and get functions as well as tools to slice 2D and 3D data, calculate axes, etc. for the
above listed data classes.

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
* uiPhaseSpace
* Various other yet incomplete GUI tools

These are graphical user interfaces designed to quickly browse through data and do preliminary data analysis. AnalyseGUI
is simply a wrapper for the standard plot functions, and loads simulation datasets via button clicks and dropdown menus.
It has a lot of features that speeds up data analysis and comparison between different simulations. 

The uiPhaseSpace tool does Twiss and emittance calculations for particle beams. It is the only one of the set of GUI
tools that are complete. The other ones will probably not be completed as I have stopped running Osiris simulations for
the time being.

![Analyse2D](https://raw.githubusercontent.com/wiki/Jadzia626/OsirisAnalysis/Images/Analyse2D.png)

----

# Usage Examples

## Core Data Class

### OsirisData

Usage:
```matlab
>> od = OsirisData;
```

This is the main data wrapping class. If search paths have been specified in the `LocalConfig.m` file, these folders
will be scanned and a tree of datasets stored in a struct accessible as `od.DataSets`. OsirisData also creates an
OsirisConfig object that is stored as `od.Config`.

The `od.Config.Input` is a struct representing the raw variables from the input file. This is unparsed data generated
by the file reading function of the OsirisConfig class. Many of the key variables, including simulation parameters, is
extracted and organised in a more easily accessible way in the other structs.

Conversion factors for fields, densities, currents, length, time, etc., is calculated on the fly when the input file is
loaded. These are available from the `Convert` struct. The CGS units is incomplete, but the SI section should have most
conversion factors needed.

**Note:** Since Osiris is in most cases ignorant of the reference plasma density of the simulation, the internal plasma
density is essentially just 1. The unit of length is the plasma skin depth, so changing the reference plasma density
also changes all dimensions of the simulation. It is therefore useful to always have a fixed normalising plasma density
that isn't necessarily the physical plasma density of your simulation. Otherwise you have to recalculate all dimensions,
beam sizes, etc. when you change density. Instead you can use the `density` parameter in the input file to scale the
physics. Therefore also the analysis code operates with a simulation density, `SimN0`, that is the basis of all scaling
parameters, while it tried to guess the physics density by evaluating the plasma density profile and setting `PhysN0`.
These values can be overwritten. Generally `PhysN0` is set to the maximum density encountered along the simulation axis.

#### Accessing Data

To access the data from a loaded dataset, run the function `od.Data()`.

Example:
```matlab
>> aData = od.Data(0,'DENSITY','Charge','EB');
```

This returns a matrix of the charge density for the electron beam from data dump 0 (start of simulation). The Data
function mainly just forwards the request to the hdf5 library to extract the data requested, but also checks if it
actually exists first. The Osiris data dump has a slightly varying naming scheme, so this class makes it easier to
access the different data dumps with a simple function call.

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

**Multiple Similar Species**

You can append a number 1-9 behind any of these variables.

**Shorthand Format**

You can for instance write 'EB' instead of 'ElectronBeam', 'PE' for 'PlasmaElectrons', 'EB1' for 'ElectronBeam1', etc.

**Naming Translation**

All variable name translations is done in the Variables class. Look at the internal map for more details. For particle
species you can add your own variable names at the end of the `LocalConfig.m` file if you want to add more.

## Data Type Classes

All classes have a similar constructor, but different methods for processing data. They all take an OsirisData object as
first input, and species type as second if relevant. These are the only required inputs. More inputs can be specified
with standard MATLAB name/value pairs. See the description in the header for each class which inputs are accepted.
Generally the all accept specifying units (SI, normalised, etc) in the constructor. Axis scales can also be set.

The object is initiated at data dump 0, but this can be changed by setting the property `Time` to a different data dump
number.

Example:
```matlab
oCH = Charge(od, 'EB', 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
oCH.Time = 10;
```

For the methods available in each of these data type classes, see the respective class headers, and function headers.
Generally I have just added all my often used calculations to each data type class instead of bloating the plot scripts.

----

# That's it!

Hope some of this is useful to others.

As I no longer run a lot of simulations with Osiris, I have also stopped developing this tool. Some features are
incomplete, especially the higher level ones.
