function PPopt %(k)

%% Globals and objective [obj(i) = 1] preferences

%Predator-Prey GA for Multi-Objective Opt
%PP
%Predator-Prey GA for Multi-Objective Opt
clc
global LB UB obj
global Setslog figure_handle no_x no_y lattice
global generation F_bad setno

RandStream('mt19937ar','seed', sum(100*clock));
figure_handle = [];

plst = {'\PP_util' '\util'};
for i = 1:length(plst)
    path([pwd plst{i}], path);
end
%===============User Input=======================================
obj(1) = -1;             %set 1 for min and -1 for max
obj(2) = -1;             %set 1 for min and -1 for max

%add more objectives here

n_obj = length(obj);

Setslog = {};
%%                          
start_out_index = 3;
default = {'Trained'};
hidden_nodes = 6;
data_filename = {'Test_data.mat'};
start_out_index = start_out_index-1; %????


for i=1:n_obj %5%% %=============UPto number of objectives
    Setslog(i) = cellstr(strcat(default,num2str(hidden_nodes),'-',num2str(start_out_index+i),'_',data_filename));
end
    
%{
% if constraint is applicable
%for constraint function introduce Setslog(3) and so on
% Setslog(3) = {'Setslog10-8_data_mod_smb1.mat'};
% Setslog(4) = {'Setslog10-9_data_mod_smb1.mat'};
%loadwlog loads the tree from Setslog file, the prototype:
%loadwlog(Setslog, setno, index);
%setno is the training subset used and index is tree index obtained from
%the pareto front of training, 1 being the tree with lowest error seeting
%setno =0 takes the last training subset and index = 0 sets the default
%tree chosen by BioGP training
%}

for i=1:n_obj
    wlog(i) = loadwlog(importdata(Setslog{i}), 0, 0);
    %wlog(2) = loadwlog(importdata(Setslog{2}), 0, 0);
end
%define extra wlog for checking the contraint and edit the contra function
%as desired
novar = length(wlog(1).in_index);

LB = []; UB = []; svstr = 'pareto_';

for i = 1:n_obj
    LB = [LB; wlog(i).xmin];
    UB = [UB; wlog(i).xmax];
    svstr = [svstr num2str(obj(i)*wlog(i).out_index) '_'];
end

%% defining variables
LB = max(LB); UB = min(UB);

Prey_popsize = 500;         %Initial popsize
no_Prey_preferred = 500;    %Desired popsize
no_new_Prey = 200;          %new prey introduced every KillInterval
Predator_popsize = 100;     %Number of Predators

no_generations = 100;       %max generations
P_move_prey = 0.5;          %Prob with which a Prey moves
P_mut = 0.1;                %prob of choosing a prey for mutation
%Prob of Xover is 1 for every Prey
F_bad = 1e5;                %fitness assigned to preys performing badly
%2D-lattice
no_x = 50;                  %lattice size (no of rows)
no_y = 50;                  %lattice size (no of cols)
KillInterval = 4;          %Interval at which bad preys are eliminated
maxrank = 4;               %maxrank retained at KillInterval
ploton = 1;                 %set 0 for no plots or 1 for plots at every generation
%=============================DND=========================================
%% Plotting Code
Setslog.generations = no_generations; Setslog.ploton = ploton;
Setslog.Predator_popsize = Predator_popsize; Setslog.Prey_popsize = Prey_popsize;
if Setslog.ploton
    figure_handle = [figure(1) figure(2) figure(3) figure(4)];
    scrsz = get(0,'ScreenSize'); setno = [];
    set(figure_handle(1), 'OuterPosition', [0*scrsz(3) scrsz(4)/2 scrsz(3)/2 scrsz(4)/2]); clf
    set(figure_handle(2), 'OuterPosition', [scrsz(3)/2 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2]); clf
    set(figure_handle(3), 'OuterPosition', [0*scrsz(3) 0*scrsz(4) scrsz(3)/2 scrsz(4)/2]); clf
    set(figure_handle(4), 'OuterPosition', [scrsz(3)/2 0*scrsz(4) scrsz(3)/2 scrsz(4)/2]); clf
    pause(0.1)
end


%**************************************************
%% Lattice initialisation
lattice = zeros(no_x+2,no_y+2);
%% initialization and location of Prey_pop 

Prey = rand(Prey_popsize,novar);
for i = 1:novar
    Prey(:,i) = Prey(:,i)*(UB(i)-LB(i))+LB(i);
end

    %location of prey
for i = 1:length(Prey)
    [emptyx,emptyy] = find(lattice(2:no_x+1,2:no_y+1) == 0);
    if ~isempty(emptyx > 0)
        j = ceil(rand*(length(emptyx)));
        lattice(emptyx(j)+1,emptyy(j)+1) = i;
    end
end

  %==============================================================================
%% initialization and location of Predator_pop
%Predators = (0:1/(Predator_popsize-1):1)'; %value to weight F1

Predators = rand(Predator_popsize, n_obj);
Predators_sum = sum(Predators,2);
one = ones(1,n_obj);
Predators_broadcast = Predators_sum*one;
Predators = Predators./Predators_broadcast;

%Make sure that the predator is initialised Properly
tol = 1.0e-14;
assert(isequal(abs(Predators_sum-ones(Predator_popsize,1))<repmat(tol,Predator_popsize,1),ones(Predator_popsize,1)),'Predator not initialised properly');

% location of predators

for i = 1:length(Predators(:,1))
    [emptyx,emptyy] = find(lattice(2:no_x+1,2:no_y+1) == 0);
    if ~isempty(emptyx > 0)
        j = ceil(rand*(length(emptyx)));
        lattice(emptyx(j)+1,emptyy(j)+1) = -i; %Predator indentified with neg values
    end
end
MovePrey(0, 0, 0);

%%

% GENERATIONS
for generation = 1:no_generations  
    Prey_new = [];
    len = length(Prey(:,1));
    % Move of prey /10 trials /1step
    for i = 1:len
        if rand < P_move_prey
            %Identify location
            [xpos,ypos] = find(lattice(2:no_x+1,2:no_y+1) == i);
            xpos = xpos+1; ypos = ypos+1;
            for j = 1:10 %10 trial for free spot
                dx = round(rand*(3-eps)-1.5); %-1 to the left, 0 no move, 1 to the right
                dy = round(rand*(3-eps)-1.5); %-1 down, 0 no move, 1 up
                if lattice(xpos+dx,ypos+dy) == 0
                    lattice(xpos,ypos) = 0; %removing prey i
                    MovePrey(xpos+dx, ypos+dy, i); break
                end
            end
        end
    end
    
        % Breeding of prey
    for i = 1:len
        [xpos,ypos] = find(lattice(2:no_x+1,2:no_y+1) == i);
        xpos = xpos+1; ypos = ypos+1;
        moore = lattice(xpos-1:xpos+1,ypos-1:ypos+1);
        %Remove the i-prey
        moore(2,2) = 0;
        [matex,matey] = find(moore >= 1 & moore <= len);
        if ~isempty(matex)
            parent2 = ceil(rand*length(matex));
            parent2 = lattice(xpos-2+matex(parent2),ypos-2+matey(parent2));
            %**********Crossover*********************
            Offspring = Prey([i;parent2],:);
            Offspring = XOVER(Offspring);
            %**********Mutations*********************
            for j = 1:2
                if rand < P_mut
                    Offspring(j,:) = MUTE(Offspring(j,:), generation);
                end
            end
            %Random location of offspring /10 trials
            %Placing offsprings
            for l = 1:2
                for j = 1:10 %10 trial for free spot
                    xpos = round(rand(1,1)*(no_x-1)+1)+1;
                    ypos = round(rand(1,1)*(no_y-1)+1)+1;
                    if lattice(xpos,ypos) == 0
                        Prey = [Prey; Offspring(l,:)];
                        lattice(xpos,ypos) = length(Prey(:,1));
                        break
                    end
                end
            end
        end
        MovePrey(0, 0, 0);
    end
    
    F = [];
    for i=1:n_obj
        F = [F, obj(i)*evalF(Prey, wlog, i)];
    end
    
    %{
    F1 = obj(1)*evalF(Prey, wlog, 1);
    F2 = obj(2)*evalF(Prey, wlog, 2);
    [F1 F2] = contra(Prey, obj(1)*F1, obj(2)*F2, wlog);
    F1 = obj(1)*F1;
    F2 = obj(2)*F2;
    %}
    
    % Doing something with K optimality
    %{
    IsKoptimal = 1;
    K = 0.45;
    
    if IsKoptimal == 1
        [] = K_dominance_SORT([F1 F2],K);
    else
        [fonrank front] = NONDOM_SORT([F1 F2]);
    
    end
    %}
    
    % Removing all except rank n
    if generation/KillInterval == round(generation/KillInterval)
        if generation == no_generations
            maxrank = 0;
        else
            Prey_new = rand(no_new_Prey,novar);
            for i = 1:novar
                Prey_new(:,i) = Prey_new(:,i)*(UB(i)-LB(i))+LB(i);
            end
        end
        
        %=========================================================
        %Tagging Bad Solutions
        indfr = find(fonrank > maxrank);
        F1(indfr) = F_bad+eps; F2(indfr) = F_bad+eps;
        
        %=========================================================
        [Prey F1 F2] = KillBadPrey(Prey, F1, F2);
        [fonrank front] = NONDOM_SORT([F1 F2]);
        %=========================================================
    end
    
    % Move of predators /killing
    crodit = CROW_SORT([F1 F2], front);
    f1 = (F1 - min(F1))./(max(F1) - min(F1));
    f2 = (F2 - min(F2))./(max(F2) - min(F2));
    
    
    PredMoves = floor((length(Prey) - no_Prey_preferred)/Predator_popsize);
    fprintf('\nGeneration %i: Predatorpop %i PredMoves %i\n',generation,length(Predators(:,1)),PredMoves);
    fprintf('Preypop before: %i; Preypop after: ', length(Prey(:,1)))
    for i = 1:length(Predators)
        for k = 1:PredMoves
            [xpos, ypos] = find(lattice(2:no_x+1,2:no_y+1) == -i); % FIND PREDATOR LOCATION
            xpos = xpos+1; ypos = ypos+1;
            [matex,matey] = find(lattice(xpos-1:xpos+1,ypos-1:ypos+1) > 0);
            if length(matex) > 1 %prey available
                rows=[];
                for t = 1:length(matex)
                    rows = [rows; lattice(matex(t)+xpos-2,matey(t)+ypos-2)];
                end
                %=========================================================
                f = (Predators(i)*f1(rows) + (1-Predators(i))*f2(rows)).*(front(rows)-1); % elitism for front = 1
                
                if length(unique(front(rows))) == 1
                    f = (f+1)./(1+crodit(rows));
                end
                %=========================================================
                [~,pos] = max(f);
                j = rows(pos(1)); lattice(xpos,ypos) = 0; %removing predator i
                [xpos,ypos] = find(lattice(2:no_x+1,2:no_y+1) == j);
                xpos = xpos+1; ypos = ypos+1;
                Prey = MovePredator(Prey, xpos, ypos, i, j);
                f1(j) = []; f2(j) = []; front(j) = []; crodit(j) = [];
                F1(j) = []; F2(j) = []; fonrank(j) = [];
            else %Only move
                for j=1:10 %10 trial for free spot
                    dx=round(rand(1,1)*(3-eps)-1.5); %-1 to the left, 0 no move, 1 to the right
                    dy=round(rand(1,1)*(3-eps)-1.5); %-1 down, 0 no move, 1 up
                    if lattice(xpos+dx,ypos+dy)==0
                        lattice(xpos,ypos)=0; %removing predator i
                        Prey = MovePredator(Prey, xpos+dx, ypos+dy, i, inf);
                        break
                    end
                end
            end
        end
    end
    fprintf('%i\n' , length(Prey(:,1)))

    PlotLattice
    %=========================================================
    PlotPareto(obj(2)*F2, obj(1)*F1, fonrank)
    %=========================================================
    
    % Placing new Prey
    for i = 1:length(Prey_new)
        for k = 1:10 %10 trial for free spot
            [emptyx,emptyy] = find(lattice(2:no_x+1,2:no_y+1) == 0);
            if ~isempty(emptyx > 0)
                j = ceil(rand*length(emptyx));
                lattice(emptyx(j)+1,emptyy(j)+1) = length(Prey(:,1)) + 1;
                Prey = [Prey; Prey_new(i,:)]; break
            end
        end
    end
    
end

%=========================================================
F1 = obj(1)*evalF(Prey, wlog, 1);
F2 = obj(2)*evalF(Prey, wlog, 2);

[F1 F2] = contra(Prey, obj(1)*F1, obj(2)*F2, wlog);
F1 = obj(1)*F1;
F2 = obj(2)*F2;
[fonrank, front] = NONDOM_SORT([F1 F2]);

PlotPareto(obj(2)*F2, obj(1)*F1, fonrank)

%=========================================================


Prey = Prey(front == 1,:); 

%=========================================================
F1 = F1(front == 1); F2 = F2(front == 1);

f = [(1:length(F1))' F1 F2]; f = sortrows(f, 3); f = sortrows(f, 2); i = 2;
%=========================================================




% ??? 

while i ~= length(f(:,1))
    if f(i,2) == f(i-1,2), f(i,:) = []; else i = i+1; end
end
pareto.P = Prey(f(:,1),:);
pareto.F1 = F1(f(:,1));
pareto.F2 = F2(f(:,1));
pareto.cons = [];
if length(wlog) > 2
   
    for i = 3:length(wlog)
        pareto.cons = [pareto.cons evalF(pareto.P, wlog, i)];
    end
end
eval(['save ' svstr(1:length(svstr)-1) ' pareto']);


%=========================================================
for i = 1:length(plst)
    rmpath([pwd plst{i}]);
end

end

function wlog = loadwlog(Setslog, setno, index)
wlog.nonodes = Setslog.nonodes;
wlog.noinnodes = Setslog.noinnodes;
wlog.nooutnodes = Setslog.nooutnodes;
wlog.Xmin = Setslog.Xmin;
wlog.Xmax = Setslog.Xmax;
f_index = Setslog.out_index;
wlog.ymin = Setslog.Data_min(1,f_index);
wlog.ymax = Setslog.Data_max(1,f_index);
wlog.xmin = Setslog.Data_min(1,Setslog.in_index);
wlog.xmax = Setslog.Data_max(1,Setslog.in_index);
if index == 0, index = Setslog.dataset(1).pareto.select; end
if setno == 0, setno = Setslog.no_run; end
Net = Setslog.dataset(setno).pareto.P(index);
wlog.w = Net.w;
wlog.W = Net.W;
wlog.in_index = Setslog.in_index;
wlog.out_index = f_index;
end

function out = evalF(Prey, wlog, oi)

Xmin = wlog(oi).Xmin; Xmax = wlog(oi).Xmax;
ymin = wlog(oi).ymin; ymax = wlog(oi).ymax;
xmin = wlog(oi).xmin; xmax = wlog(oi).xmax;
nonodes = wlog(oi).nonodes; noinnodes = wlog(oi).noinnodes;
nooutnodes = wlog(oi).nooutnodes;
w = wlog(oi).w; W = wlog(oi).W;

in = Prey; noexp = length(in(:,1));

%rescaling the input to actual values
for i = 1:length(wlog(oi).in_index)
    in(:,i) = Xmin + (in(:,i)-xmin(i))/(xmax(i)-xmin(i))*(Xmax-Xmin);
end

%calculating output from neural net.
s = zeros(noexp,1); z = [];
for i = 1:nonodes,
    s(:) = w(i,1)*ones(noexp,1)+((w(i,2:noinnodes+1)*in')');
    z(:,i) = 1./(1+exp(-s(:)));
end
A = [ones(noexp,1) z];
bber = A*W;
for i = 1:nooutnodes
    bber(:,i) = ymin(i)+(ymax(i)-ymin(i))*(bber(:,i)-Xmin)/(Xmax-Xmin);
end
out = bber;
end

function [F1 F2] = contra(Prey, F1, F2, wlog)  % constraint function

% global obj
% 
% penalty = 1e1;               % Penalty to be set by user
% 
% LB_F = [0.4 0 0.9 0.7];       %set lower bound for F1,F2,F3,F4 and so on respectively
% UB_F = [1 10 1 1];            %set upper bound for F1,F2,F3,F4 and so on respectively
% F3 = evalF(Prey, wlog, 3);
% F4 = evalF(Prey, wlog, 4);
% F = [F1 F2 F3 F4];
% flag = 0;
% for i = 1:length(F1)
%     for j = 1:length(F(1,:))
%         if F(i,j) < LB_F(j) || F(i,j) > UB_F(j)
%             flag = 1;
%         end
%     end
%     if flag
%         F1(i) = F1(i) + obj(1)*penalty;
%         F2(i) = F2(i) + obj(2)*penalty;
%     end
%     flag = 0;
% end

end