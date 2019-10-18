clear all
close all
clc
%% Taking audio input and lowpass filtering 
[y, fs] = audioread('hand.mp3');
y = y(:,1);
y1 = fir1(500,1/3);
y = filter(y1,1,y);

%% Changing the sample rate
convfs = 22050;
m = lcm(fs,convfs);
p = m/fs;
q = m/convfs;
x = resample(y,p,q);

%% Buffer the file into 20-30 ms bits
frameLength = 512;
x1 = buffer(x,frameLength);

%% Finding energy and eliminating low energy portion
energy = sum(x1.^2,1)