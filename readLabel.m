function label = readLabel(filename,classNames)
% Ließt Bezeichnung des Ordners (0/1) -> Speichert diese in caegorical Variable Label ab

filepath = fileparts(filename);
[~,label] = fileparts(filepath);

label = categorical(string(label),classNames);

end