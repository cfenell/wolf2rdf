function [ionogram,meta]=wolfread(filename);
% Load and uncompress ionogram with metadata
% NB: for single-ionogram SO166 format data files only.
% Use ionoload.m from ionobrowse [(C) Thomas Ulich] to read multiple-ionogram files.
%
% v0.2: in-memory gunzip included in this m file
% v0.1: calling edited version of dunzip.m for decompression
%
% C-F Enell 2012

%Open the file for reading
[fid,err]=fopen(filename,'r');
%Check if file was found
if(fid<0)
  error(err);
end
frewind(fid); %make sure pointer is at first byte

%Read the file format description (4 ASCII formatted numbers)
lhead=fscanf(fid,'%u',1); %length of header
ldata=fscanf(fid,'%u',1); %length of data block
nlf=fscanf(fid,'%u',1);   %number of separating LFs 
lfile=fscanf(fid,'%u',1); %total length of file
fread(fid,1,'*char'); %skip LF byte after first line

%Check the file format data
if(lhead+ldata+nlf~=lfile)
  error('Corrupt or not a single-measurement file')
end

%Read the header
header=fread(fid,lhead,'*char');
header=header';

%Read the compressed data block
comprdata=fread(fid,ldata,'*uint8');

%Close the input file
fclose(fid);

%Evaluate the header to extract metadata (It is Matlab code!)
%This defines a set of variables. Used below are
% SCode_, time_, lat_, lon_, postfix, uncompressor, dtype
eval(header);

%Return metadata for RDF header
meta.ursicode=SCode_;
meta.year=time_(1);
meta.month=time_(2);
meta.day=time_(3);
meta.hour=time_(4);
meta.min=time_(5);
meta.geolat=lat_;
meta.geolong=lon_;
meta.comment=['SGO ionogram ',title_(51:end)]; %max 55 chars
meta.mode=mode_;

%Uncompress ionogram
try  
  
  %Uncompress data in memory by calling Java functions
  %See dunzip.m (C) Michael Kleder, Nov 2005,
  %code available from MatlabCentral
  import com.mathworks.mlwidgets.io.InterruptibleStreamCopier
  a=java.io.ByteArrayInputStream(comprdata);
  b=java.util.zip.GZIPInputStream(a);
  isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
  c = java.io.ByteArrayOutputStream;
  isc.copyStream(b,c);
  data=typecast(c.toByteArray,dtype); %as specified data type
  data=double(data); %cast from dtype to double

catch  % in case other compressor than gzip was used ...
  %Dump compressed data to temporary file
  [x,tmpfile]=system('mktemp -u'); %prepare a unique name without creating file
  tmpfile=strtrim(tmpfile); %remove linefeeds from output of mktemp
  [fid,err]=fopen([tmpfile,postfix],'w'); %open file for writing
  %Check if file was created
  if(fid<0)
    error(err);
  end
  fwrite(fid,comprdata,'uint8'); %write data as unsigned integer
  fclose(fid);
  
  %Uncompress data to file (without postfix).
  system([uncompressor,' ',tmpfile,postfix,' > ',tmpfile]); 
                                                              
  %Read the uncompressed data
  fid=fopen(tmpfile,'r');
  %Check if file was opened
  if(fid<0)
    error(err);
  end
  data=fread(fid,Inf,dtype); %read the whole file

  %Clean up
  system(['rm -f ',tmpfile,'*']);

end

%Map to original values according to specification
data=(110-19).*data./(2^nbits-1);
data(data>0)=data(data>0)+19;

%Reshape vector to ionogram matrix
ionogram=reshape(data,rowcol);

%%% EOF
