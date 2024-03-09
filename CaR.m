%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CaR: A Cutting and Repulsion-based Evolutionary Framework for Mixed-Integer Programming Problems
% Authors: Jiao Liu,  Yong Wang
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = CaR(Parameters)
%% 参数初始化
func_num = Parameters.func_num;
Swarm_Set = Choose_func(func_num);
X = Initialization(Parameters,Swarm_Set);
X = BestIndvidual(X);

t = 0;
Arc = [];
T = 800;
FEs = 0;

%% 记录历史最优解
X.x_best = X.x_best_cur;
X.x_best_val = X.x_best_val_cur;
X.x_best_consvec = X.x_best_consvec_cur;
X.x_best_cons = X.x_best_cons_cur;

while FEs <= 2e5
    X = PreviousBest(X);
    for i = 1:Parameters.pop
        v(i,:) = DE_generator(X,Swarm_Set,Parameters,i);

        SelEva = CuttingEva(v(i,:),X,Parameters.func_num,i);
    
        SelEva = RepulsionEva(SelEva,X,v(i,:),Swarm_Set.idx_I,Arc,i);
    
        X = DebSel(SelEva,X,v(i,:),i);

        FEs = FEs + 1;
    end 
    X = BestIndvidual(X);
    
    [t,Arc] = RenewArc(t,X,Arc);
    if t > T
        Arc = [Arc;X.x_best_cur];
        X = Initialization(Parameters,Swarm_Set,X);
        t = 0;
    end
end

if X.x_best_cons == 0
    out.best_val = X.x_best_val;
    out.best_x   = X.x_best;
else
    out.best_val = NaN;
    out.best_x   = NaN*ones(1,Swarm_Set.len_x);
end

function [t,Arc,X] = RenewArc(t,X,Arc)
e_best = abs(X.x_best_val_cur - X.x_best_val_pre);
e_cons = abs(X.x_best_cons_cur - X.x_best_cons_pre);
if (X.x_best_cons_cur <= 0)&&(e_best < 1e-8)
    t = t+1;
elseif (X.x_best_cons_cur > 0)&&(e_cons < 1e-8)%&&(e_pop < 1e-6)
    t = t+1;
else
    t = 0;
end

function X = DebSel(SelEva,X,v,i)
%Renew Current
if (SelEva.v_cons_cut > 0)&&(SelEva.x_cons_cut > 0)
    if SelEva.v_cons_cut <= SelEva.x_cons_cut
        X.x(i,:) = v;
        X.val(i,:) = SelEva.v_val;
        X.cons(i,:) = SelEva.v_cons;
    end
elseif (SelEva.v_cons_cut <= 0)&&(SelEva.x_cons_cut > 0)
    X.x(i,:) = v;
    X.val(i,:) = SelEva.v_val;
    X.cons(i,:) = SelEva.v_cons;
elseif (SelEva.v_cons_cut <= 0)&&(SelEva.x_cons_cut <= 0)
    if SelEva.v_val <= SelEva.x_val 
        X.x(i,:) = v;
        X.val(i,:) = SelEva.v_val;
        X.cons(i,:) = SelEva.v_cons;
    end
end

%Renew Best
if (SelEva.v_cons_cut > 0)&&(X.x_best_cons > 0)
    if SelEva.v_cons_cut <= X.x_best_cons
        X.x_best = v;
        X.x_best_val = SelEva.v_val;
        X.x_best_cons = SelEva.v_cons;
    end
elseif (SelEva.v_cons_cut <= 0)&&(X.x_best_cons > 0)
    X.x_best = v;
    X.x_best_val = SelEva.v_val;
    X.x_best_cons = SelEva.v_cons;
elseif (SelEva.v_cons_cut <= 0)&&(X.x_best_cons <= 0)
    if SelEva.v_val <= X.x_best_val
        X.x_best = v;
        X.x_best_val = SelEva.v_val;
        X.x_best_cons = SelEva.v_cons;
    end
end

function CutEva = CuttingEva(v,X,func_num,i)
%The Cutting Strategy
if X.x_best_cons > 0
    fcons = inf;
else
    fcons = X.x_best_val;
end

%Evaluate Indivuidual v
[v_val,v_cons_vec] = test_func(v,func_num);
v_cons = sum(v_cons_vec);

%Cutting Evaluate
x_cons_cut = X.cons(i,:) + max(0,X.val(i,:) - fcons);
v_cons_cut = v_cons + max(0,v_val - fcons);

%Output
CutEva.x_val = X.val(i,:);
CutEva.v_val = v_val;
CutEva.x_cons_cut = x_cons_cut;
CutEva.v_cons_cut = v_cons_cut;
CutEva.x_cons = X.cons(i,:);
CutEva.v_cons = v_cons;

function SelEva = RepulsionEva(SelEva,X,v,idx_I,Arc,i)
%Repulsion V
if ~isempty(Arc)
    dis_ham_v = min(sum( (v(:,idx_I) ~= Arc(:,idx_I)),2) );
else
    dis_ham_v = 1;
end

if dis_ham_v == 0
   repulsion_v = 1e6;
else
   repulsion_v = 0;
end

%Repulsion X
if ~isempty(Arc)
    dis_ham_x = min(sum( (X.x(i,idx_I) ~= Arc(:,idx_I)),2) );
else
    dis_ham_x = 1;
end

if dis_ham_x == 0
   repulsion_x = 1e6;
else
   repulsion_x = 0;
end

SelEva.x_cons_cut = SelEva.x_cons_cut + repulsion_x;
SelEva.v_cons_cut = SelEva.v_cons_cut + repulsion_v;

function v = DE_generator(X,Swarm_Set,Parameters,i)
% Parameters
len_x = Swarm_Set.len_x;
up_x  = Swarm_Set.up_x;
dn_x  = Swarm_Set.dn_x;
idx_I = Swarm_Set.idx_I;

alpha = Parameters.alpha;

x = X.x;
x_best_cur = X.x_best_cur;
[pop,~] = size(x);
F = 0.5;
CR = 0.9;

% Mutation
if Parameters.operator_num == 1
    rand_sel = randperm(pop,3);
    u = x(rand_sel(1),:) + F*(x(rand_sel(2),:) - x(rand_sel(3),:));
elseif Parameters.operator_num == 2
    rand_sel = randperm(pop,5);
    u = x(rand_sel(1),:) + F*(x(rand_sel(2),:) - x(rand_sel(3),:)) + F*(x(rand_sel(4),:) - x(rand_sel(5),:));
elseif Parameters.operator_num == 3 
    rand_sel = randperm(pop,3);
    u = x(i,:) + rand*(x(rand_sel(1),:) - x(i,:)) + F*(x(rand_sel(2),:) - x(rand_sel(3),:));
else
    rand_sel = randperm(pop,3);
    u = x(rand_sel(1),:) + rand*(x_best_cur - x(rand_sel(1),:)) + F*(x(rand_sel(2),:) - x(rand_sel(3),:));
end
    
% Crossover
rand_cr = rand([1,len_x]);
v = (rand_cr>=CR).*x(i,:) + (rand_cr<CR).*u;
        
jrand = ceil(len_x*rand);
v(:,jrand) = u(:,jrand);

% Repair
v = (v>=up_x).*max(dn_x,2*up_x-v) + (v<up_x).*v;
v = (v<=dn_x).*min(up_x,2*dn_x-v) + (v>dn_x).*v;

% Truncation
v(:,idx_I) = alpha*round(v(:,idx_I)/alpha);

function [X] = Initialization(Parameters,Swarm_Set,X)
if nargin == 2
    X = [];
else
    X = X;
end 

len_x = Swarm_Set.len_x;
up_x  = Swarm_Set.up_x;
dn_x  = Swarm_Set.dn_x;
idx_I = Swarm_Set.idx_I;
pop   = Parameters.pop;
func_num = Parameters.func_num;
alpha    = Parameters.alpha;

x = repmat(up_x-dn_x,pop,1).*rand(pop,len_x) + repmat(dn_x,pop,1);

for i = 1:pop
    x(i,idx_I) = alpha*round(x(i,idx_I)/alpha);
    [value_x(i,:),cons_x_vec(i,:)] = test_func(x(i,:),func_num);
    cons_x(i,:) = sum(cons_x_vec(i,:));
end

X.x = x;
X.val = value_x;
X.cons_vec = cons_x_vec;
X.cons = cons_x;

function X = BestIndvidual(X)
idx_fea = (X.cons == 0);
if sum(idx_fea) == 0
    [~,idx_best] = min(X.cons);
    
    X.x_best_cur = X.x(idx_best,:);
    X.x_best_val_cur = X.val(idx_best,:);
    X.x_best_consvec_cur = X.cons_vec(idx_best,:);
    X.x_best_cons_cur = X.cons(idx_best,:);
else
    x_fea = X.x(idx_fea,:);
    x_fea_val  = X.val(idx_fea,:);
    x_fea_cons_vec = X.cons_vec(idx_fea,:);
    x_fea_cons = X.cons(idx_fea,:);
    
    [~,idx_best] = min(x_fea_val);
    
    X.x_best_cur = x_fea(idx_best,:);
    X.x_best_val_cur = x_fea_val(idx_best,:);
    X.x_best_consvec_cur = x_fea_cons_vec(idx_best,:);
    X.x_best_cons_cur = x_fea_cons(idx_best,:);
end

function X = PreviousBest(X)
X.x_best_pre = X.x_best_cur;
X.x_best_val_pre = X.x_best_val_cur;
X.x_best_consvec_pre = X.x_best_consvec_cur;
X.x_best_cons_pre = X.x_best_cons_cur;

