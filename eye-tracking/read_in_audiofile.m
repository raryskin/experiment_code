
function audio_in_buffer = read_in_audiofile(sounds_dir, audiochannel,audio_file)

    %sprintf([char(sounds_dir), char(audio_file)])
    [audiofortrial, ~] = audioread([char(sounds_dir), char(audio_file)]); 
    audio_in_buffer = PsychPortAudio('CreateBuffer' , audiochannel, audiofortrial');
    
end
    
