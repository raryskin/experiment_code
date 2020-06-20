 function [tex,imgH,imgW, imgD] = img_to_tex(pics_dir,img,window)
    [pic, ~, ~] =imread([char(pics_dir),char(img),'.jpg']);
    [imgH, imgW, imgD]=size(pic);
    tex=Screen('MakeTexture',window,pic);
    
    end
