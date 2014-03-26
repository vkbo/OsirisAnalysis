%
%  Script: sConstants
% **********************
%  Generates a struct of constants

Constants.Math      = {};
Constants.Nature    = {};
Constants.Particles = {};
Constants.Units     = {};

% Mathematical constants

Constants.Math.Pi                        =  3.141592653589793; % Dimensionless
Constants.Math.TwoPi                     =  6.283185307179586; % Dimensionless

%
% Nature
%

% Fundamental
Constants.Nature.SpeedOfLight            =  2.99792458e8;      % m/s (exact)
Constants.Nature.Planck                  =  6.62606957e-34;    % J·s
Constants.Nature.PlanckEV                =  4.135667516e-15;   % eV·s
Constants.Nature.Gravity                 =  6.67384e-11;       % N·m^2 / kg^2
Constants.Nature.Boltzmann               =  1.3806488e-23;     % J/K
Constants.Nature.BoltzmannEV             =  8.6173324e-5;      % eV/K

% Other
Constants.Nature.ElementaryCharge        =  1.602176565e-19;   % C
Constants.Nature.VacuumPermitivity       =  8.854187817e-12;   % F/m 
Constants.Nature.VacuumPermeability      =  1.2566370614e-6;   % N/A^2
Constants.Nature.HBar                    =  1.054571726e-34;   % J·s
Constants.Nature.HBarEV                  =  6.58211928e-16;    % eV·s

%
% Particles
%

% Electron
Constants.Particles.Electron             =  {};
Constants.Particles.Electron.Mass        =  9.10938291e-31;    % kg
Constants.Particles.Electron.MassMeV     =  5.109989282e-1;    % MeV/c^2
Constants.Particles.Electron.Charge      = -1.602176565e-19;   % C
Constants.Particles.Electron.ChargeE     = -1.0;               % e
Constants.Particles.Electron.MagneticDPM = -9.284764e-30;      % J/T
Constants.Particles.Electron.Spin        =  0.5;               % 
Constants.Particles.Electron.MeanLife    =  1.0e1000;          % s

% Proton
Constants.Particles.Proton               =  {};
Constants.Particles.Proton.Mass          =  1.672621777e-27;   % kg
Constants.Particles.Proton.MassMeV       =  9.38272046e2;      % MeV/c^2
Constants.Particles.Proton.Charge        =  1.602176565e-19;   % C
Constants.Particles.Proton.ChargeE       =  1.0;               % e
Constants.Particles.Proton.MagneticDPM   =  1.4106067e-28;     % J/T
Constants.Particles.Proton.Spin          =  0.5;               %
Constants.Particles.Proton.MeanLife      =  5.9013e36;         % s (minimum)

% Neutron
Constants.Particles.Neutron              =  {};
Constants.Particles.Neutron.Mass         =  1.674927351e-27;   % kg
Constants.Particles.Neutron.MassMeV      =  9.39565378e2;      % MeV/c^2
Constants.Particles.Neutron.Charge       =  0.0;               % C
Constants.Particles.Neutron.ChargeE      =  0.0;               % e
Constants.Particles.Neutron.MagneticDPM  = -9.66236e-27;       % J/T
Constants.Particles.Neutron.Spin         =  0.5;               %
Constants.Particles.Neutron.MeanLife     =  8.815e2;           % s

% Muon
Constants.Particles.Muon                 =  {};
Constants.Particles.Muon.Mass            =  1.883532e-28;      % kg
Constants.Particles.Muon.MassMeV         =  1.056583715e2;     % MeV/c^2
Constants.Particles.Muon.Charge          = -1.602176565e-19;   % C
Constants.Particles.Muon.ChargeE         = -1.0;               % e
Constants.Particles.Muon.MagneticDPM     = -4.4904478e-28;     % J/T
Constants.Particles.Muon.Spin            =  0.5;               %
Constants.Particles.Muon.MeanLife        =  2.1969811e-6;      % s

% Alpha
Constants.Particles.Alpha                =  {};
Constants.Particles.Alpha.Mass           =  6.64465675e-27;    % kg
Constants.Particles.Alpha.MassMeV        =  3.727379240e3;     % MeV/c^2
Constants.Particles.Alpha.Charge         =  3.20435313e-19;    % C
Constants.Particles.Alpha.ChargeE        =  2.0;               % e
Constants.Particles.Alpha.MagneticDPM    =  0.0;               % J/T
Constants.Particles.Alpha.Spin           =  0.0;               %


%
% Units
%

% Electron Volt [eV]
Constants.Units.ElectronVolt             =  {};
Constants.Units.ElectronVolt.Energy      =  1.602176565e-19;   % J      [eV]
Constants.Units.ElectronVolt.Mass        =  1.782662e-36;      % kg     [eV/c^2]
Constants.Units.ElectronVolt.Momentum    =  5.344286e-28;      % kg·m/s [eV/c]
Constants.Units.ElectronVolt.Temperature =  1.1604505e4;       % K      [eV/k_B]
Constants.Units.ElectronVolt.Time        =  6.582119e-16;      % s      [ħ/eV]
Constants.Units.ElectronVolt.Distance    =  1.97327e-7;        % m      [ħc/eV]
