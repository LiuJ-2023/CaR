clear
Parameters.pop      = 60;

for opera = 1:4
Parameters.operator_num = opera;
for rep = 1:16
    Parameters.func_num = rep;
    if rep == 8
        Parameters.alpha    = 20;
    elseif rep == 9
        Parameters.alpha    = 50;
    elseif rep == 10
        Parameters.alpha    = 100;
    elseif rep == 13
        Parameters.alpha    = 20;
    elseif rep == 14
        Parameters.alpha    = 50;
    else
        Parameters.alpha    = 1;
    end

    for i = 1:25
        out = CaR(Parameters);
        
        Car_data(opera).val(i,rep) = out.best_val;
        Car_data_x{rep,opera}(i,:) = out.best_x;
%         best_ind_bi{rep}(i,:) = out.best_x;

        clc
        fprintf('Current Test Problem: %d \n',rep);
        fprintf('The %dth Run \n',i);
        fprintf('Current Best Objective Function Value: %E \n',out.best_val);
    end
end
end




