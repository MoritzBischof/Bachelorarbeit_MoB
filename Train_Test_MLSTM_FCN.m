%% Model Architektur 
clear all; clc; close all;

destination = {'Train\'; 'Test\'; 'Validation\'};   % Namen der Sub-Folders
dest_path = 'C:\Users\user\Documents\MoB\Training\1und2_5als0_5und7_5als1\1\';   % Dateipfad der Daten für das Netztraining

clearvars -except dest_path destination ; clc; close all;

Input_Vars = 11;  % Anzahl der Netzinput-Variablen 
nr_classes = 2;   % Anzahl der zu klassifzierenden Klassen
drop_rate = 0.7;  % Dropout Rate 
Size_conv1 = 128; % Größe conv1d_1 & conv1d_3

layers = [
    sequenceInputLayer(Input_Vars, 'Normalization', 'zscore')

    convolution1dLayer(8,Size_conv1, 'Padding', 'same', 'WeightsInitializer', 'he');
    batchNormalizationLayer('Epsilon', 0.001)
    reluLayer('Name', 'relu1')
    dropoutLayer(drop_rate)

        globalAveragePooling1dLayer;
        fullyConnectedLayer(Size_conv1/16);
        reluLayer('Name', 'relu_se1');
        fullyConnectedLayer(Size_conv1);
        sigmoidLayer('Name', 'sig1');
        functionLayer(@(X) addDimension(X), Formattable=true, Name= 'CB to CBT 1')

    multiplicationLayer(2, 'Name', 'multiply 1')

    convolution1dLayer(5,256, 'Padding', 'same', 'WeightsInitializer', 'he');
    batchNormalizationLayer('Epsilon', 0.001)
    reluLayer('Name', 'relu2')
    dropoutLayer(drop_rate)

        globalAveragePooling1dLayer;
        fullyConnectedLayer(256/16);
        reluLayer('Name', 'relu_se2');
        fullyConnectedLayer(256);
        sigmoidLayer('Name', 'sig2');
        functionLayer(@(X) addDimension(X), Formattable=true, Name= 'CB to CBT 2')
    
    multiplicationLayer(2, 'Name', 'multiply 2')

    convolution1dLayer(3,Size_conv1, 'Padding', 'same', 'WeightsInitializer', 'he');
    batchNormalizationLayer('Epsilon', 0.001)
    reluLayer('Name', 'relu3')
    dropoutLayer(drop_rate)  
    globalAveragePooling1dLayer
    
    concatenationLayer(1,2)

    fullyConnectedLayer(nr_classes);
    softmaxLayer
    classificationLayer()
    ];

lgraph = layerGraph(layers);

layers = [ 
    lstmLayer(8, OutputMode='last')
    dropoutLayer(0.8)];

lgraph = addLayers(lgraph,layers);
lgraph = connectLayers(lgraph,'sequenceinput', 'lstm');
lgraph = connectLayers(lgraph,'dropout_1', 'multiply 1/in2');
lgraph = connectLayers(lgraph,'dropout_2', 'multiply 2/in2');
lgraph = connectLayers(lgraph,'dropout',"concat/in2");

% analyzeNetwork(lgraph)

%% Set Training Options

classNames = string(0:1);

% Erzeuge file-Datastores für aufgenommene Zeitreihen
fdsPredictorTrain = fileDatastore([dest_path destination{1}], ...
    "ReadFcn",@load,"FileExtensions",".mat", ...
    "IncludeSubfolders",true);

fdsPredictorVal = fileDatastore([dest_path destination{3}], ...
    "ReadFcn",@load,"FileExtensions",".mat", ...
    "IncludeSubfolders",true);

% Erzeuge file-Datastores mit Info über Label der betrachteten Zeitreihe
fdsLabelTrain = fileDatastore([dest_path destination{1}], ...
    'ReadFcn',@(filename) readLabel(filename,classNames), ...
    'IncludeSubfolders',true);

fdsLabelVal = fileDatastore([dest_path destination{3}], ...
    'ReadFcn',@(filename) readLabel(filename,classNames), ...
    'IncludeSubfolders',true);

sequenceLength = 15000;
tdsTrain = transform(fdsPredictorTrain,@(data) padSequence(data,sequenceLength));
tdsVal = transform(fdsPredictorVal,@(data) padSequence(data,sequenceLength));

% Füge Datastores zusammen
cdsTrain = combine(tdsTrain,fdsLabelTrain);
cdsVal = combine(tdsVal,fdsLabelVal);

% Training Options
maxepochs = 250;
miniBatchSize = 32;
valFreq = 30;

options = trainingOptions("adam", ...
    MaxEpochs= maxepochs, ...
    MiniBatchSize= miniBatchSize,...
    LearnRateSchedule="piecewise",...
    InitialLearnRate= 0.001, ...
    LearnRateDropPeriod= 100,...
    LearnRateDropFactor= 0.7937,...  
    Shuffle="every-epoch",...
    Verbose=false, ...
    ExecutionEnvironment='gpu', ...
    Plots="training-progress", ...
    ValidationData= cdsVal, ...
    ValidationFrequency=valFreq, ...
    CheckpointPath= [dest_path 'checkpoints\'], ...
    CheckpointFrequency=5);

%% Train Network
net = trainNetwork(cdsTrain,lgraph,options);

net_all_drop02learn2_NR1 = net;

str = [ dest_path 'training_drop_0_5_learn2'];
save([str '.mat'] )

%% Test Network
destination = {'Train\'; 'Test\'; 'Validation\'}; 
dest_path = 'C:\Users\user\Documents\MoB\Training\1_0_und_5_0\mit_Schwankungen\starke_Anstrengung\NUR_sensordata\1\'; % Dateipfad der Testdaten

% Erzeuge file-Datastores
fdsPredictorTest = fileDatastore([dest_path destination{2}], ...
    "ReadFcn",@load,"FileExtensions",".mat", ...
    "IncludeSubfolders",true);

fdsLabelTest = fileDatastore([dest_path destination{2}], ...
    'ReadFcn',@(filename) readLabel(filename,classNames), ...
    'IncludeSubfolders',true);

tdsTest = transform(fdsPredictorTest,@(data) padSequence(data,sequenceLength));

cdsTest = combine(tdsTest,fdsLabelTest);

% Klassifiziere Testdaten
YPred = classify(net,cdsTest,'MiniBatchSize',miniBatchSize);

% get Test Labels
YTest = readall(fdsLabelTest);

for i = 1:length(YTest)
    YY(i,1) =  YTest{i,1};
end

YTest = YY;

acc = sum(YPred == YTest)./numel(YTest);

% Erzeuge Confusionmatrix
conf = plotconfusion(YTest, YPred);
set(findobj(gca,'type','text'),'fontsize',12) 


% ROC erstellen
YPred2 = predict(net,cdsTest,'MiniBatchSize',miniBatchSize); %1x2 Matrix mit Wsk. für [0 1]
YTest2 = grp2idx(YTest)-1; % -1, da 0 -> 1 und 1 -> 2 wird durch Funktion grp2idx
YTest2 = single(YTest2);
[X,Y] = perfcurve(YTest2, YPred2(:,2), '1'); % (:,2) beinhaltet WSK für positive Label (Leckage)

figure
plot(X,Y)
xlabel('False positive rate') 
ylabel('True positive rate')
title('ROC for Classification by Logistic Regression')

rocObj = rocmetrics(YTest2, YPred2(:,2), '1');
plot(rocObj)

