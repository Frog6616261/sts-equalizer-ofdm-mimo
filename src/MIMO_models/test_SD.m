clear all; close all; clc

 M = 16;
 H = Generate_random_channel_matrix(2, 2);
 cons = qammod(0:M-1, M);
   
 % Test all symbols = first constellation point
 sym_rx = H * cons(1) * ones(2,10); % 10 timeslots
 LLRs = LLSD_mes_list(sym_rx, H, M, 100); % High SNR
    
  % All LLRs should be large negative (for Gray 0000)
  if any(LLRs > 0)
      error('Polarity error detected!');
  else
      fprintf('Test passed: %.1f%% LLRs correct\n',...
            100*mean(LLRs < 0));
  end