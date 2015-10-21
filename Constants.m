%
%  Script: sConstants
% **********************
%  Generates a struct of constants

stConstants.Math      = {};
stConstants.Nature    = {};
stConstants.Particles = {};
stConstants.Units     = {};

% Mathematical constants

stConstants.Math.Pi                        =  3.141592653589793; % Dimensionless
stConstants.Math.TwoPi                     =  6.283185307179586; % Dimensionless

%
% Nature
%

% Fundamental
stConstants.Nature.SpeedOfLight            =  2.99792458e8;      % m/s (exact)
stConstants.Nature.Planck                  =  6.62606957e-34;    % J·s
stConstants.Nature.PlanckEV                =  4.135667516e-15;   % eV·s
stConstants.Nature.Gravity                 =  6.67384e-11;       % N·m^2 / kg^2
stConstants.Nature.Boltzmann               =  1.3806488e-23;     % J/K
stConstants.Nature.BoltzmannEV             =  8.6173324e-5;      % eV/K

% Other (SI)
stConstants.Nature.ElementaryCharge        =  1.602176565e-19;   % C
stConstants.Nature.ElementaryChargeCGS     =  4.80320425e-10;    % statC
stConstants.Nature.VacuumPermitivity       =  8.854187817e-12;   % F/m 
stConstants.Nature.VacuumPermeability      =  1.2566370614e-6;   % N/A^2
stConstants.Nature.HBar                    =  1.054571726e-34;   % J·s
stConstants.Nature.HBarEV                  =  6.58211928e-16;    % eV·s

% Other (CGS)
stConstants.Nature.ElementaryChargeCGS     =  4.80320425e-10;    % statC

%
% Particles
%

% Electron
stConstants.Particles.Electron             =  {};
stConstants.Particles.Electron.Mass        =  9.10938291e-31;    % kg
stConstants.Particles.Electron.MassMeV     =  5.109989282e-1;    % MeV/c^2
stConstants.Particles.Electron.MassAtomic  =  5.485799095e-4;    % u
stConstants.Particles.Electron.Charge      = -1.602176565e-19;   % C
stConstants.Particles.Electron.ChargeE     = -1.0;               % e
stConstants.Particles.Electron.MagneticDPM = -9.284764e-30;      % J/T
stConstants.Particles.Electron.Spin        =  0.5;               % 
stConstants.Particles.Electron.MeanLife    =  1.0e1000;          % s

% Proton
stConstants.Particles.Proton               =  {};
stConstants.Particles.Proton.Mass          =  1.672621777e-27;   % kg
stConstants.Particles.Proton.MassMeV       =  9.38272046e2;      % MeV/c^2
stConstants.Particles.Proton.MassAtomic    =  1.007276466812;    % u
stConstants.Particles.Proton.Charge        =  1.602176565e-19;   % C
stConstants.Particles.Proton.ChargeE       =  1.0;               % e
stConstants.Particles.Proton.MagneticDPM   =  1.4106067e-28;     % J/T
stConstants.Particles.Proton.Spin          =  0.5;               %
stConstants.Particles.Proton.MeanLife      =  5.9013e36;         % s (minimum)

% Neutron
stConstants.Particles.Neutron              =  {};
stConstants.Particles.Neutron.Mass         =  1.674927351e-27;   % kg
stConstants.Particles.Neutron.MassMeV      =  9.39565378e2;      % MeV/c^2
stConstants.Particles.Neutron.MassAtomic   =  1.00866491600;     % u
stConstants.Particles.Neutron.Charge       =  0.0;               % C
stConstants.Particles.Neutron.ChargeE      =  0.0;               % e
stConstants.Particles.Neutron.MagneticDPM  = -9.66236e-27;       % J/T
stConstants.Particles.Neutron.Spin         =  0.5;               %
stConstants.Particles.Neutron.MeanLife     =  8.815e2;           % s

% Muon
stConstants.Particles.Muon                 =  {};
stConstants.Particles.Muon.Mass            =  1.883532e-28;      % kg
stConstants.Particles.Muon.MassMeV         =  1.056583715e2;     % MeV/c^2
stConstants.Particles.Muon.Charge          = -1.602176565e-19;   % C
stConstants.Particles.Muon.ChargeE         = -1.0;               % e
stConstants.Particles.Muon.MagneticDPM     = -4.4904478e-28;     % J/T
stConstants.Particles.Muon.Spin            =  0.5;               %
stConstants.Particles.Muon.MeanLife        =  2.1969811e-6;      % s

% Alpha
stConstants.Particles.Alpha                =  {};
stConstants.Particles.Alpha.Mass           =  6.64465675e-27;    % kg
stConstants.Particles.Alpha.MassMeV        =  3.727379240e3;     % MeV/c^2
stConstants.Particles.Alpha.MassAtomic     =  4.001506179125;    % u
stConstants.Particles.Alpha.Charge         =  3.20435313e-19;    % C
stConstants.Particles.Alpha.ChargeE        =  2.0;               % e
stConstants.Particles.Alpha.MagneticDPM    =  0.0;               % J/T
stConstants.Particles.Alpha.Spin           =  0.0;               %


%
% Units
%

% Electron Volt [eV]
stConstants.Units.ElectronVolt             =  {};
stConstants.Units.ElectronVolt.Energy      =  1.602176565e-19;   % J      [eV]
stConstants.Units.ElectronVolt.Mass        =  1.782662e-36;      % kg     [eV/c^2]
stConstants.Units.ElectronVolt.Momentum    =  5.344286e-28;      % kg·m/s [eV/c]
stConstants.Units.ElectronVolt.Temperature =  1.1604505e4;       % K      [eV/k_B]
stConstants.Units.ElectronVolt.Time        =  6.582119e-16;      % s      [ħ/eV]
stConstants.Units.ElectronVolt.Distance    =  1.97327e-7;        % m      [ħc/eV]
