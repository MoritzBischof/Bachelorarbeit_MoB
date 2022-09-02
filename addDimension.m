function X = addDimension(X)
%Fügt Dimension nach globalavgpooling hinzu -> aus CB -> CBT

X(end, end,15000) = 1;
X = dlarray(X, 'CBT');
end