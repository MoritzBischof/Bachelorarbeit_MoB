%% Preprocessing Multivariate Time Series
% Funktionen des Skripts:
%           Unterteilung der aufgenommenen Szenarie/Zeitreihen in gleichgroße Abschnitte
%           Erstellung und Split der aufgenommenen Datensätze in Training, Test & Validation
%           Abspeichern in seperaten Ordnern zur Erzeugung von fileDatastores

% Ablauf des Skripts:
%           1. Lade alle aufgenommenen Datensätze
%           2. Zerlege jedes aufgenommene Szenario/Zeitreihe(18min) in gleich große Abschnitte
%           3. Speicher jeden Abschnitt in seperater .mat-file -> unterscheidung von Sollzustand/Leckage
%           4. Splitte Daten in Training, Test & Validation 
%           5. Erstelle Ordner und speicher Daten in diesen

%% Datenablageorte 
clear all; clc

% Dateipfad an dem Ordner mit .mat files angelegt werden soll 
dest_path = 'C:\Users\user\Documents\MoB\';

destination = {'Train\'; 'Test\'; 'Validation\'}; %Name der zu erstellenden Ordner in dest_path

addpath('C:\Users\user\Documents\MoB\natsortfiles\'); % Ordne Files nach Nummern in Dateinamen
addpath = ('C:\Users\user\Documents\MoB\');

% Dateipfade der gewünschten Daten
datenorte1 = {'C:\Users\user\Documents\MoB\Datengenerierung\Sollzustand\'}; 
datenorte2 = {'C:\Users\user\Documents\MoB\Datengenerierung\Leckagen\'}; 

% Datenablageorte mit folgender Teilbezeichnung werden ausgeschlossen
 ausschluss = {'2_5', '5_0'}; 


%% Zusammenführung aller Einzeldateien aus den Datenablageorten

dateien=[];
for d=datenorte1
    dateien = [dateien;get_files_to_process(d{1},'.mat')];
end
for a=ausschluss
    idx_a=contains(dateien,a{1});
    dateien(idx_a)=[];
    disp([num2str(sum(idx_a)) ' "' a{1} '"-Dateien ausgeschlossen. Es verbleiben ' num2str(length(dateien)) ' Dateien.']);
end
L_1 = length(dateien); %Anzahl Dateien Sollzustand

for d=datenorte2
    dateien = [dateien;get_files_to_process(d{1},'.mat')];
end

% Ausschluss
for a=ausschluss
    idx_a=contains(dateien,a{1});
    dateien(idx_a)=[];
    disp([num2str(sum(idx_a)) ' "' a{1} '"-Dateien ausgeschlossen. Es verbleiben ' num2str(length(dateien)) ' Dateien.']);
end

%% Einteilung in Sequenzabschnitte
% Zeitreihe in Abschnitte der Länge l = 15000 timesteps einteilen

for SeqNr = 1:15
    
    mkdir(fullfile([dest_path num2str(SeqNr)]));
    dest_path = [dest_path num2str(SeqNr) '\'];


    %Erstelle Ordner für .mat files (0: Keine Leckage, 1:Leckage)
    mkdir(fullfile([dest_path '0\']));
    mkdir(fullfile([dest_path '1\']));
    mkdir(fullfile([dest_path 'checkpoints\'])); %für Training Checkpoints

    for j = 1:length(dateien)
        clear X Y
        load(dateien{j})

        % Wähle Parameter aus sensor- & controllerData, die als Netzinput dienen sollen
        sens = table2array(sensordata(30000:end,[2,3,4,5,6,10,11,13,16,19]));
        cont = table2array(controllerData(30000:end,[25,26,27,40,50,51,52,53,54,55]));

        clear sensordata controllerData

        start = (SeqNr-1)*15000 +1; %Startzeitpunkt Sequenzabschnitt
        ende = SeqNr*15000;         %Endzeitpunkt Sequenzabschnitt

        if size(sens,1) < ende
           disp('Länge der aktuellen Zeitreihe (dateien(stimmt nicht überein')     
        else
        data = {[sens(start:ende,:) cont(start:ende,:)]'}; % Netzwerkinput

        tmp = num2str(SeqNr); % Nr. Sequnezabschnitt

        if j <= L_1 
            folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_SN_dicht.mat'],'data'); 
        end

        if j > L_1 
            if contains(dateien{j},'1_0') %|| contains(dateien{j},'2_5')
                if contains(dateien{j},'HPR') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_HPR_Leck_1_0.mat'],'data'); end
                if contains(dateien{j},'LPR') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_LPR_Leck_1_0.mat'],'data'); end
                if contains(dateien{j},'Zwischen') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_HPRzuLPR_Leck_1_0.mat'],'data'); end
                if contains(dateien{j},'LV') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_LV_Leck_1_0.mat'],'data'); end
                if contains(dateien{j},'RV') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_RV_1_0.mat'],'data'); end
            end
            if contains(dateien{j},'2_5') %|| contains(dateien{j},'2_5')
                if contains(dateien{j},'HPR') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_HPR_Leck_2_5.mat'],'data'); end
                if contains(dateien{j},'LPR') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_LPR_Leck_2_5.mat'],'data'); end
                if contains(dateien{j},'Zwischen') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_HPRzuLPR_Leck_2_5.mat'],'data'); end
                if contains(dateien{j},'LV') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_LV_Leck_2_5.mat'],'data'); end
                if contains(dateien{j},'RV') folder = [dest_path '0\']; save([folder num2str(j) '_' tmp '_RV_2_5.mat'],'data'); end
            end
            if contains(dateien{j},'5_0') %|| contains(dateien{j},'2_5')
                if contains(dateien{j},'HPR') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_HPR_Leck_5_0.mat'],'data'); end
                if contains(dateien{j},'LPR') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_LPR_Leck_5_0.mat'],'data'); end
                if contains(dateien{j},'Zwischen') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_HPRzuLPR_Leck_5_0.mat'],'data'); end
                if contains(dateien{j},'LV') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_LV_Leck_5_0.mat'],'data'); end
                if contains(dateien{j},'RV') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_RV_5_0.mat'],'data'); end
            end
            if contains(dateien{j},'7_5') %|| contains(dateien{j},'2_5')
                if contains(dateien{j},'HPR') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_HPR_Leck_7_5.mat'],'data'); end
                if contains(dateien{j},'LPR') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_LPR_Leck_7_5.mat'],'data'); end
                if contains(dateien{j},'Zwischen') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_HPRzuLPR_Leck_7_5.mat'],'data'); end
                if contains(dateien{j},'LV') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_LV_Leck_7_5.mat'],'data'); end
                if contains(dateien{j},'RV') folder = [dest_path '1\']; save([folder num2str(j) '_' tmp '_RV_Leck_7_5.mat'],'data'); end
            end
        end
        clear data
        end
    end

%% Train, Test, Validation Split

% Dateipfad aus dem .mat-files geladen werden
datenorte = {[dest_path '0\']; [dest_path '1\'] };

% Zielpfad, an denen .mat-files nach Split abgelegt werden
destination = {'Train\'; 'Test\'; 'Validation\'}; %Name der zu erstellenden Ordner in dest_path

for i = 1:length(datenorte) %Schleife über angegebene Datenorte(-> Classification Labels)
   
    %Zusammenführen der Dateipfade 
    dats=[];
    for d=datenorte(i,1)
        dats = [dats;get_files_to_process(d{1},'.mat')];
    end

    sequences = dats; %Zeitreihen-Sequenzabschnitte

    trainSize=0.7;
    valSize=0.15;
    testSize=0.15;

    % Create the training data
    cv=cvpartition(size(sequences,1),'HoldOut',valSize+testSize);  
    idx=cv.test;
    % Separate to training and test data
    dataTrain = sequences(~idx,:);
    dataValTest  = sequences(idx,:);

    % Create validation and test data
    ratio = testSize/(testSize+valSize);
    cv=cvpartition(size(dataValTest,1),'HoldOut', ratio);  
    idx2=cv.test;

    %Label für Klassifizierung festlegen
    if i == 1 label = '0'; end
    if i == 2 label = '1'; end

    location = {find(~idx); find(idx2); find(~idx2)}; % Info, ob Datei zu training, test oder validierung 
    
    for m = 1:length(location)
        mkdir(fullfile([dest_path destination{m,1}], label)); % Erstelle Ordner(Train,Test,Validation) mit Label in akt. Pfad
        for j = 1:length(location{m,1})
            source = dats{location{m,1}(j,1)}; %aktuelle .mat-file
            movefile(source, [dest_path destination{m,1} label '\']); %verschiebe .mat-file in Ordner
        end
        if m == 1; dats(find(~idx),:) = []; end  %Lösche Pfade von bereits verschobenen .mat-files
        
    end
end

clearvars -except dateien L_1 dest_path destination ende start; clc
end