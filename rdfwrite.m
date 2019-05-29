function rdfwrite(outgram,rdfpar,metadata)
% Write ionogram in RDF format for Autoscala
% See documentation available from Scotto et al
%
% Usage: rdfwrite(outgram,rdfpar,metadata)
% outgram: Ionogram matrix in fixed f,h resolution 
% rdfpar:  Struct defining f and h resolution for RDF header. Minumum content:
%  rdfpar.ifreq Initial frequency
%  rdfpar.ffreq Final frequency
%  rdfpar.fstep Frequency step
%  rdfpar.ihgt  Initial height
%  rdfpar.fhgt  Final height
%  rdfpar.hstep Height step
% metadata: Struct of metadata from original SO166 ionogram header
% For minimum content see the code below
%
% v 0.1
%
% (C) C-F Enell 2012

%Output file name convention: YYJJJHMM.rdf (DOS 8.3 format)
%YY:  year (2 digits)
%JJJ: Julian day
%H:   hour letter, 00=A, 01=B etc
%MM:  minute
ofyear=metadata.year-2000;
hourletter=char(double('A')+metadata.hour);
jdate=datenum([metadata.year metadata.month metadata.day])-datenum([metadata.year 1 1])+1;
ofname=sprintf('%2.2d%3.3d%1s%2.2d.rdf',ofyear,jdate,hourletter,metadata.min);

%Open file for writing
[fid,err]=fopen(ofname,'w');
%Check if file was created
if(fid<0)
  error(err);
end

%% Write RDF header to file
%Parameters from rdfpar
fprintf(fid,'%6.3f ',rdfpar.ifreq);
fprintf(fid,'%6.3f ',rdfpar.ffreq);
fprintf(fid,'%5.3f ',rdfpar.fstep);
fprintf(fid,'%5.1f ',rdfpar.ihgt);
fprintf(fid,'%5.1f ',rdfpar.fhgt);
fprintf(fid,'%3.1f ',rdfpar.hstep);

%Dummy values to comply with RDF format
fprintf(fid,'%2s ','xx');     %int attenuation
fprintf(fid,'%2s ','xx');     %ext attenuation
fprintf(fid,'%1s ','x');      %amplification
fprintf(fid,'%4s ','xxxx');   %filter high
fprintf(fid,'%4s ','xxxx');   %filter low
fprintf(fid,'%2s ','xx');     %integrations
fprintf(fid,'%1s ','x');      %software version
fprintf(fid,'%6s ','xxxxxx'); %Available
%Parameters from metadata
fprintf(fid,'%52s ',metadata.comment); %Comment
fprintf(fid,'%2s ',metadata.mode);     %Mode
fprintf(fid,'%5s ',metadata.ursicode); %URSI station code
fprintf(fid,'%4.4d ',metadata.year);   %YYYY
fprintf(fid,'%2.2d ',metadata.month);  %MM
fprintf(fid,'%2.2d ',metadata.day);    %DD
fprintf(fid,'%3.3d ',jdate);           %Day number
fprintf(fid,'%2.2d:%2.2d ',metadata.hour,metadata.min); %hh:mm
fprintf(fid,'+%4.1f ',metadata.geolat); %Geographic latitude
fprintf(fid,'%5.1f ',metadata.geolong); %Geographic longitude 
fprintf(fid,'+%4.1f ',metadata.maglat); %Magnetic longitude
fprintf(fid,'%5.1f ',metadata.maglong); %Magnetic latitude
fprintf(fid,'%4.2f ',metadata.gyrofreq); %Gyrofrequency
fprintf(fid,'+%4.1f ',metadata.incl);   %Magnetic inclination

%File name
fprintf(fid,'%12s',ofname);

%End of header: LF
fprintf(fid,'\n');
%% RDF header written

%Check that RDF header is 197 bytes
if ftell(fid)~=197
  error('Something wrong with size of header !!')
end

%Check size of ionogram matrix
if size(outgram,1)~=150
  error('Wrong resizing: RDF file should always contain 150 heights!!')
  fclose(fid)
end

%Cast as 8-bit integer 0-255
outgram=int8(round(outgram));

%Write data to RDF file
for k=1:size(outgram,2)
  fwrite(fid,outgram(:,k),'integer*1');
end

%Close file
fclose(fid);
%%% EOF
