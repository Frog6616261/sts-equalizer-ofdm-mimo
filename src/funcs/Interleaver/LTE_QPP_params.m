function [f1, f2] = LTE_QPP_params(K)
% LTE_QPP_PARAMS 

    switch K
        case 40
            f1 = 3;   f2 = 10;
        case 48
            f1 = 7;   f2 = 12;
        case 56
            f1 = 19;  f2 = 42;
        case 64
            f1 = 7;   f2 = 16;
        case 72
            f1 = 7;   f2 = 18;
        case 80
            f1 = 11;  f2 = 20;
        case 88
            f1 = 5;   f2 = 22;
        case 96
            f1 = 11;  f2 = 24;
        case 104
            f1 = 7;   f2 = 26;
        case 112
            f1 = 41;  f2 = 84;
        case 128
            f1 = 16; f2 = 32;
        case 256
            f1 = 15;  f2 = 64;
        case 512
            f1 = 31;  f2 = 64;
        case 1024
            f1 = 31;  f2 = 128;
        case 2048
            f1 = 63;  f2 = 256;
        otherwise
            error('Неподдерживаемая длина блока K=%d', K);
    end
end

