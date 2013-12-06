%% TEST SCRIPT 
%  Provides data to compare with YUV method

vid_frame = imread('vid_frame.jpg');
diff_im = imsubtract(vid_frame(:,:,1), rgb2gray(vid_frame)); 
bw1_im = im2bw(diff_im, 0.18);
noise_im = medfilt2(diff_im, [3 3]);
bw2_im = im2bw(noise_im,0.18); 
area_im = bwareaopen(bw_im,10000);
areas = logical(area_im);
obj_prop = regionprops(areas, 'Area', 'BoundingBox', 'Centroid');
obj_prop

%% Show and export image after each processing step
imshow(vid_frame(:,:,1)), title('Red Component')
figure, imshow(vid_frame(:,:,2)), title('Green Component')
figure, imshow(vid_frame(:,:,3)), title('Blue Component')
figure, imshow(rgb2gray(vid_frame)), title('Grayscale')
figure, imshow(diff_im), title('Difference')
figure, imshow(noise_im), title('Median Filtered')
figure, imshow(bw1_im), title('Binary before filter')
figure, imshow(bw2_im), title('Binary after filter')
figure, imshow(area_im), title('Regions Filtered')

imwrite(vid_frame(:,:,1), '2Dredcomp.jpg');
imwrite(vid_frame(:,:,2), '2Dgreencomp.jpg');
imwrite(vid_frame(:,:,3), '2Dbluecomp.jpg');
imwrite(rgb2gray(vid_frame), '2Dgrayscale.jpg');
imwrite(diff_im, '2Ddiff.jpg');
imwrite(noise_im, '2Dnoise.jpg');
imwrite(bw1_im, '2Dbinarynofilt.jpg');
imwrite(bw2_im, '2Dbinaryfilt.jpg');
imwrite(area_im, '2Dregions.jpg');

