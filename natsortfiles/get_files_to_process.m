%% Auflistung aller Dateien in Dateipfad
%MoB added natsortfiles -> alphanumeric sort by filename

%% Recursively loop through all subfolders
function files = get_files_to_process(database_path, extension)

% initialise table for output
files = cell(0,1);

if isempty(database_path) || ~isdir(database_path)
    fprintf('\nThe path you specified for looking for *%s files is either empty or corrupted.\nPlease fix your input path.\n', extension);
    return;
end
    
fprintf('\nRecursivley searching for *%s files', extension);
files = search_subfolders(database_path, files, extension);

% subfunction to search through folders recursively
function files = search_subfolders(curr_folder_path, files, extension)
      % list whats inside the folder
        S = dir(curr_folder_path);
        inside = natsortfiles(S); % alphanumeric sort by filename
%       inside = dir(curr_folder_path); %alternative if natsortfiles is not used 
      % remove the '.' and '..' folders from the list
      inside(ismember({inside(:).name},{'.'; '..'})) = [];
      % get the struct containing only files
      inside_files   = inside(~[inside.isdir]);
      % get the struct containing only folders
      inside_folders = inside([inside.isdir]);

      % if there are files 
      if ~isempty(inside_files)
          % check if they contain the specified extension
          files_idx = endsWith({inside.name}, extension, 'IgnoreCase', true);              
          if any(files_idx)
               % add them to the main array
              files = [files; cellfun(@(x,y) [x, filesep, y], {inside(files_idx).folder}, {inside(files_idx).name}, 'UniformOutput', 0 )'];
          end
      end
      % recursively loop through all found sub folders
      if ~isempty(inside_folders)
          for i = 1:size(inside_folders, 1)
              files = search_subfolders([inside_folders(i).folder, filesep, inside_folders(i).name], files, extension);
          end
      end
      fprintf('.');
end

fprintf('\nFinished. %d found.\n', size(files,1));
end