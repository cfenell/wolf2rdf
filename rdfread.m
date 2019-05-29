function [header,f,h,ogram,xgram]=rdfread(fname);
%Matlab routine for reading RDF ionograms
% See RDF specification by Scotto et al.
%
% Usage: [header,f,h,ogram,xgram]=rdfread(fname)
% 
% Input: fname (name of RDF file)
% 
% Output: header (RDF header)
%         f      (frequency grid)
%         h      (altitude grid) 
%         ogram  (o mode ionogram matrix)
%         xgram  (x mode ionogram matrix)
%
% v0.2: reads x and o mode if available
% v0.1: read only o mode
%
% (C) C-F Enell 2012

%

%%% Open the RDF file
[fid,message]=fopen(fname,'r');
if(fid<0)
  error(message)
end
frewind(fid)

%%% Read header bytes
header=fread(fid,197,'*char');
header=header'; %column to row

%%% Frequency and height ranges from header
%f
fmin=str2double(header(1:6));
fmax=str2double(header(8:13));
fstep=str2double(header(15:19));
f=fmin:fstep:fmax;
nf=length(f);
%h
hmin=str2double(header(21:25));
hmax=str2double(header(27:31));
hstep=str2double(header(33:35));
h=hmin:hstep:hmax;
nh=length(h);

%%% Polarization modes from header
themodes=header(120:121);

%%% Initialise
ogram=zeros(nh,nf);
xgram=zeros(nh,nf);

%%% Read binary data
for k=1:nf,
  %If O mode is available, it is the 1st 150-height record
  if strfind(themodes,'O') > 0
    ogram(:,k)=fread(fid,nh);
  end
  %If X mode is available, it is the 2nd or only 150-height record
  if strfind(themodes,'X') > 0
    xgram(:,k)=fread(fid,nh);
  end
end


%%% Close the file
fclose(fid);

%%% EOF