function wolf2rdf(ionogram,outpath)
% Conversion of SGO ionograms to RDF format for Autoscala
%
% This function reads Alpha Wolf standard SO166 format ionograms,
% resamples to a defined (frequency,altitude) grid,
% and writes the resampled ionogram to an RDF file.
%
% Usage: wolf2rdf(ionogram,outpath)
% 
% ionogram: path to analyzed ionogram (SO166yyyymmddhhmm.166)
% outpath:  directory for RDF file output (current directory if not specified)
%           Name of output file follows RDF standard YYJJJHMM.rdf
%
% v0.1
%
% (C) C-F Enell 2012

%% Fixed parameters of Alpha Wolf ionogram (change if sounding changes)
% These are not in the ionogram file header? ...
fmin=0.5262; %MHz
fmax=15.9665;
hmin=2.8617; %km
hmax=1.5024e+03;


%% Set up parameters for RDF file output
% Frequency grid
rdfpar.ifreq=1.0;   %Initial frequency  [>=1 MHz]
rdfpar.ffreq=16.0;  %Final frequencty   [<=20 MHz]
rdfpar.fstep=0.05;   %Frequency step    [0.05, 0.1, 0.2 or 0.5 MHz]

% Height grid, 150 heights required, 
rdfpar.ihgt=90.0;   %Initial height     
rdfpar.fhgt=760.5;  %Final height
rdfpar.hstep=4.5;   %Height step        

%% Read the Alpha Wolf ionogram
[ingram,metadata]=wolfread(ionogram);
%f,h grid of Alpha Wolf ionogram
f=fmin:(fmax-fmin)/(size(ingram,2)-1):fmax;
h=hmin:(hmax-hmin)/(size(ingram,1)-1):hmax;


%% Add missing metadata for RDF header
metadata.maglat=64.1; %Magnetic latitude
metadata.maglong=106.7; %Magnetic longitude
Babs=sqrt(51000^2+12000^2+2000^2)*1e-9; %very approximate absolute B field
metadata.gyrofreq=2.8e+4*Babs; %MHz
metadata.incl=80.0; %Inclination angle

%% Resample the ionogram to specified RDF frequency and altitude grid
fo=rdfpar.ifreq:rdfpar.fstep:rdfpar.ffreq;
ho=rdfpar.ihgt:rdfpar.hstep:rdfpar.fhgt;
[F,H]=meshgrid(f,h);
[FO,HO]=meshgrid(fo,ho);
outgram=interp2(F,H,ingram,FO,HO);

%% Write ionogram to RDF file
if(nargin>=2) %cd if output directory specified
  oldwd=pwd;
  cd(outpath)
end
rdfwrite(outgram,rdfpar,metadata)
if(nargin>=2)
  cd(oldwd)
end

%% EOF