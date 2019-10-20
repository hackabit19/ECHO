clear all
close all
clc
%% Taking audio input and lowpass filtering 
[file,path] = uigetfile({'*.mp3';'*.wav'});
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end
selectedfile = fullfile(path,file);
[y,fs] = audioread(selectedfile);
%[y, fs] = audioread('hand.mp3');
y = y(:,1);
convfs = 22050;         %Chosen value of sample rate to make sample rate constant
y1 = fir1(501,1/3);
y = filter(y1,1,y);

%% Changing the sample rate
m = lcm(fs,convfs);
p = m/fs;
q = m/convfs;
x = resample(y,p,q);

%% Defining Scope
scope = dsp.TimeScope('NumInputPorts',4,  ...
    'SampleRate',convfs, ...       
    'TimeSpan',25, ...                             
    'BufferLength',25*convfs, ... 
    'YLimits',[-1.5,1.5], ...                         
    'TimeSpanOverrunAction',"Scroll", ...
     'ShowLegend',true, ...
     'Title',"Audio Signal", ...
     'ChannelNames',{'Original Audio','Energy','Detection of voice','Corrected Audio'});
     
%% Buffer the file into 20-30 ms bits
frameLength = 512;
z = buffer(x,frameLength);

%% Finding energy and eliminating low energy portion
energy = sum(z.^2,1);
energy = energy/max(energy);
energy = repelem(energy,frameLength);
h = ones(1,2000);
energy = filter(h,1,energy);
energy = energy/max(energy);
E = energy > 0.08;

%% To find start and end of words
difference = diff(E);
time = 1:length(x);
wr = difference(1:length(x)).*time;
wr = abs(wr);
wri = nonzeros(wr);
writ = buffer(wri,2);
start = writ(1,:);
ends = writ(2,:);

%% Remove impulses assumed to be words
for n = drange (1:(length(ends)-1)) 
    if((start(n+1)-ends(n)) < 0.2*convfs)
        start(n+1) = 0;
        ends(n) = 0;
    end
end
start = nonzeros(start);
ends = nonzeros(ends);
%% Removing repetition
for n = 1:(length(ends)-1)
    word1 = x(start(n):ends(n));
    word1 = buffer(word1,frameLength);
    word2 = x(start(n+1):ends(n+1));
    word2 = buffer(word2,frameLength);
    w1 = mfcc(word1,convfs,'NumCoeffs',13,"LogEnergy","Ignore",'WindowLength',512);
    w2 = mfcc(word2,convfs,'NumCoeffs',13,"LogEnergy","Ignore",'WindowLength',512);
    s1 = size(w1);
    s2 = size(w2);
    w1 = reshape(w1,1,s1(3)*13);
    w2 = reshape(w2,1,s2(3)*13);
    dist = sqrt(sum(((w1(1:min(s1(3),s2(3)))-w2(1:min(s1(3),s2(3))))./(w1(1:min(s1(3),s2(3)))+w2(1:min(s1(3),s2(3))))).^2,2));
    if (dist<6) 
        start(n) = 0;
        ends(n) =0;
    end    
end
start = nonzeros(start);
ends = nonzeros(ends);
rep=x;
for n = 1:(length(ends)-1)
    rep(ends(n):start(n+1)) =0;
end

%% Removing long pause
gap = start(2:end) - ends(1:end-1);
gap = gap>0.15*convfs;
for n = 1:length(gap)
    if(gap)
        start(n) = start(n) - round(0.18*convfs);
        ends(n) = ends(n) + round(0.18*convfs);
    end
end
corrected = [];
for n = 1:length(ends)
    corrected = [corrected rep(start(n):ends(n))'];
end
corrected = corrected';
scope(x,energy',E',corrected)
sound(corrected,convfs)
audiowrite('finalAudio.wav',corrected,convfs);