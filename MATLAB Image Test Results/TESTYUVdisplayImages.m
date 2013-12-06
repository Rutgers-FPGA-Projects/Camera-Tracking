%% TEST SCRIPT 
%  Provides data to compare with 2D method

vid_original = imread('vid_frame.jpg');
size_img = size(vid_original);
r = 1; g = 2; b = 3;
y = 1; u = 2; v = 3;
vid_yuv = vid_original;
for i = 1:size_img(1)
    for j = 1:size_img(2)
        vid_yuv(i, j, y) = (vid_original(i, j, r) + 2*vid_original(i, j, g) + vid_original(i, j, b)) / 4;
        vid_yuv(i, j, u) = vid_original(i, j, r) - vid_original(i, j, g);
        vid_yuv(i, j, v) = vid_original(i, j, b) - vid_original(i, j, g);
    end
end
vid_detected = vid_original;
for i = 1:size_img(1)
    for j = 1:size_img(2)
        if vid_yuv(i, j, u) > 85 && vid_yuv(i, j, u) < 140
            vid_detected(i, j, r) = 255;
            vid_detected(i, j, g) = 255;
            vid_detected(i, j, b) = 255;
        else
            vid_detected(i, j, r) = 0;
            vid_detected(i, j, g) = 0;
            vid_detected(i, j, b) = 0;
        end
    end
end
vid_detected = im2bw(vid_detected);
vid_imerode = imerode(vid_detected, strel('square', 3));
vid_imfill = imfill(vid_imerode, 'holes');
[L, n] = bwlabel(vid_imfill); 
vid_region = regionprops(L, 'Area', 'BoundingBox');
vid_area = [vid_region.Area]; 
vid_idx = find(vid_area > (.45)*max(vid_area)); 
vid_idx
vid_shown = ismember(L, vid_idx);
vid_shownrp = regionprops(vid_shown, 'Area', 'BoundingBox', 'Centroid');
vid_shownrp

%% Show and export image after each processing step
imshow(vid_yuv), title('YUV Conversion')
figure, imshow(vid_yuv(:,:,1)), title('Y Component')
figure, imshow(vid_yuv(:,:,2)), title('U Component')
figure, imshow(vid_yuv(:,:,3)), title('V Component')
figure, imshow(vid_detected), title ('Raw Segmentation Result')
figure, imshow(vid_imerode), title ('Eroded Result')
figure, imshow(vid_imfill), title ('Filled Regions')
figure, imshow(vid_shown), title ('Final Result')

imwrite(vid_yuv, 'YUVyuv.jpg');
imwrite(vid_yuv(:,:,1), 'YUVycomp.jpg');
imwrite(vid_yuv(:,:,2), 'YUVucomp.jpg');
imwrite(vid_yuv(:,:,3), 'YUVvcomp.jpg');
imwrite(vid_detected, 'YUVdetected.jpg');
imwrite(vid_imerode, 'YUVeroded.jpg');
imwrite(vid_imfill, 'YUVfilled.jpg');
imwrite(vid_shown, 'YUVfinal.jpg');
