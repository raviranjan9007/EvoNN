%Getting Filenames of the Trained Neural Net (generated by PPNNGA_subsets) files

FolderName = '.\DTLZ2_2000_12_3\';
dataFile = 'DTLZ2_2000_12_3.mat';

ValidateFileDefault = dataFile;

ValidateFile = strcat(FolderName,ValidateFileDefault);

out_index = 15;
hidden_nodes = 9;  % Verify hidden_nodes from PPNNGA_subsets
% streamline this hidden nodes verification process.

n_obj = length(out_index);
start_out_index = out_index(1);
default = {'Trained_'};
%default = {'Setslog'};

start_out_index = start_out_index-1;

Setslog = {};
for i=1:n_obj %ipto #objectives
    Setslog(i) = cellstr(strcat(default,num2str(hidden_nodes),'-',num2str(start_out_index+i),'_',dataFile))
    %output_tripathi(Setslog{i});
    this = strcat(FolderName,Setslog);
    output(this{i},ValidateFile);

end
