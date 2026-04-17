function [out_x, out_y] = Replace_Zeros(in_x, in_y)
    
     mask = in_y ~= 0;
     out_x = in_x(mask);
     out_y = in_y(mask);
end

