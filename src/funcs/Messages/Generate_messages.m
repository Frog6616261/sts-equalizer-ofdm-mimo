function messages = Generate_messages(Nt, numb_frames, M)

messages = randi([0, M-1], Nt, numb_frames);

end