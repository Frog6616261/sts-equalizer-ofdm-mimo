function[X_hat]=SD_detector(y, H, NT, M, mod_func)
% Input:
%   y:receivedsignal,NRx1
%   H:Channelmatrix,NRxNT
%   NT:numberofTxantennas
%
% Output:
%   X_hat:estimatedsignal,NTx1


globalx_list; %candidatesymbolsinrealconstellations
globalx_now; %temporaryx_vectorelements
globalx_hat; %inv(H)*y
globalx_sliced; %slicedx_hat
globalx_pre; %xvectorsobtainedinthepreviousstage
globalreal_constellation;%realconstellation
globalR; %RintheQRdecomposition
globalradius_squared; %radius^2
globalx_metric; %MLmetricsofpreviousstagecandidates
globallen; %NT*2

QAM_table2=[-3-3j,-3-j,-3+3j,-3+j,-1-3j,-1-j,-1+3j,-1+j,3-3j,
3-j,3+3j,3+j,1-3j,1-j,1+3j,1+j]/sqrt(10);%16-QAM

real_constellation=[-3-113]/sqrt(10);
y=[real(y);imag(y)]; %y:complexvector->realvector
H=[real(H)-(imag(H));imag(H) real(H)];

    %H:complexvector->realvector
len=NT*2;   %complex->real
x_list=zeros(len,4);    %4:realconstellationlength,16-QAM
x_now=zeros(len,1);
x_hat=zeros(len,1);
x_pre=zeros(len,1);
x_metric=0;
[Q,R]=qr(H);    %NRxNT QRdecomposition
x_hat=inv(H)*y;     %zeroforcingequalization
x_sliced=QAM16_real_slicer(x_hat,len); %slicing
radius_squared=norm(R*(x_sliced-x_hat))^2; %Radious^2
transition=1;   %meaningoftransition
    %0:radius*2,1 len:stagenumber
    %len+1:comparetwovectorsintermsofnormvalues
    %len+2:finish
flag=1;     %transitiontracing
    %0:stageindexincreasesby+1
    %1:stageindexdecreasesby-1
    %2:1->len+2orlen+1->1
while(transition<len+2)
    if transition == 0
        % radius_squared*2
        [flag,transition, radius_squared, x_list] = radius_control(radius_squared, transition);
    elseif transition <= len
        [flag,transition] = stage_processing(flag, transition);
    elseif transition == len+1 %
        [flag,transition] = compare_vector_norm(transition);
    end
end

ML = x_pre;
for i=1:len/2
    X_hat(i) = ML(i)+1j*ML(i+len/2);
end

end