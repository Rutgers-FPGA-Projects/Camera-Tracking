%% Object Detection and Tracking 
%  Peter Tu
%  
%  Detects and tracks red objects in a frame through the use of image
%  processing filters. Frames are captured from laptop's webcam.
%
%% Some problems encountered with this method: 
%  - Sensitive to distance from camera
%  - Will detect multiple objects, impractical for PZT camera application
%  - Sensitive to luminance/lighting
%  


%% Initialize camera device
% Extract camera device info and take in video input
cam = imaqhwinfo;
cam_name = char(cam.InstalledAdaptors(end)); % Returns name of camera adaptor 
cam_info = imaqhwinfo(cam_name);             % Returns device information
cam_id = cam_info.DeviceInfo.DeviceID(end);  % Returns device ID
vid_format = char(cam_info.DeviceInfo.SupportedFormats(end)); % Returns format (resolution) of video frames

vid = videoinput(cam_name, cam_id, vid_format);

% Set the properties of the vid object
set(vid, 'FramesPerTrigger', Inf); % after running, continue taking input until infinite frames
set(vid, 'ReturnedColorspace', 'rgb') % set colorspace to rgb
vid.FrameGrabInterval = 5; % grab frame from vid every 5 frames

start(vid)

%% Set a loop that stops after 100 frames of acquisition (can set '100' to 'Inf' to acquire forever 
while(vid.FramesAcquired<=100)
    
    % Get the snapshot of the current (first) frame
    vid_frame = getsnapshot(vid); % frame returned as an HxWxB matrix; H=img height, W=img width, B=num of brands 
    
    % Subtract grayscale image from rgb red component image to extract red
    diff_im = imsubtract(vid_frame(:,:,1), rgb2gray(vid_frame)); %3 Bands, band 1 is red, 2 is g, 3 is b; normalized R+G+B=1 (neutral white)
    % ^ subtracts rgb2gray(vid_frame), a 2D matrix from 1st page of vid_frame (2D matrix)
    
%%    Try alternate method (YUV Conversion and Morphological Filtering)
%     sizevid_frame = size(vid_frame);
%     yuv_im = vid_frame;
%     for i = 1:sizevid_frame(1)
%         for j = 1:sizevid_frame(2)
%             yuv_im(i, j, 1) = (vid_frame(i, j, 1) + 2*vid_frame(i, j, 2) + vid_frame(i, j, 3)) / 4;
%             yuv_im(i, j, 2) = vid_frame(i, j, 1) - vid_frame(i, j, 3);
%             yuv_im(i, j, 3) = vid_frame(i, j, 2) - vid_frame(i, j, 3);
%         end
%     end
%     
%     im_detected = vid_frame;
%     for i = 1:sizevid_frame(1)
%         for j = 1:sizevid_frame(2)
%             %U range was found based on experiments
%             if yuv_im(i, j, 2) > 85 && yuv_im(i, j, 2) < 140
%                 %Set suspected ball regions to 1
%                 im_detected(i, j, 1) = 255;
%                 im_detected(i, j, 2) = 255;
%                 im_detected(i, j, 3) = 255;
%             else
%                 %Set non-ball regions to 0
%                 im_detected(i, j, 1) = 0;
%                 im_detected(i, j, 2) = 0;
%                 im_detected(i, j, 3) = 0;
%             end
%         end
%     end
%     
%     im_bw = im2bw(im_detected);
%     im_erode = imerode(im_bw, strel('square', 3));
%     im_fill = imfill(im_erode, 'holes');
% 
%     % Label each connected region in binary image
%     [L, n] = bwlabel(im_fill); %n gives us # of connected objects
% 
%     im_region = regionprops(L, 'Area', 'BoundingBox');
%     im_area = [im_region.Area]; % array contains areas of all the filled regions
% 
%     % Disregard regions whose areas are less than 26% largest area (supposedly a ball area)%%
%     im_idx = find(im_area > (.26)*max(im_area)); %only shows indices of regions that are balls
%     
%     im_shown = ismember(L, im_idx);
%     
%     stats = regionprops(im_shown, 'BoundingBox', 'Centroid');
    
    
    %Use a median filter to filter out noise
    noise_im = medfilt2(diff_im, [3 3]);
    % Convert the image (grayscale, 2D matrix) into a binary image.
    bw_im = im2bw(noise_im,0.18);
    
    % Remove all those pixels less than 10000px 
    area_im = bwareaopen(bw_im,10000);
    
    % Label all connected regions in image
    areas = bwlabel(area_im, 8);
    
    % Get set of properties of each labeled region:
    % boundingbox[x0 y0 W H], centroid[x0 y0]
    obj_prop = regionprops(areas, 'BoundingBox', 'Centroid');
    
    % Display the video frames
    imshow(vid_frame)  
        
    hold on
    
    % Put rectangular box around target and display centroid coordinates,
    % bounding box starting coordinates (upper left corner), and W,H of box
    for object = 1:length(obj_prop)
        targetbb = obj_prop(object).BoundingBox;
        targetcent = obj_prop(object).Centroid;
        rectangle('Position',targetbb,'EdgeColor','r','LineWidth',2)
        plot(targetcent(1),targetcent(2), '-m+')
        a=text(targetcent(1)+15,targetcent(2), strcat('X: ', num2str(round(targetcent(1))), '    Y: ', num2str(round(targetcent(2))))); % Show (x,y) coord of centroid
        b=text(targetbb(1)+15,targetbb(2)+25, strcat('W: ', num2str(round(targetbb(1)+targetbb(3))), '    H: ', num2str(round(targetbb(2)+targetbb(4))))); % Show (H,W) of region
        c=text(targetbb(1)+30,targetbb(2)+55, strcat('X0: ', num2str(round(targetbb(1))), '    Y0: ', num2str(round(targetbb(2))))); % Show (X0,Y0) of box
        set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'red');
        set(b, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'blue');
        set(c, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'blue');
    end
    
    hold off
end

% Stop the video aquisition.
stop(vid);

% Flush all the image frames stored in the memory buffer.
flushvid_frame(vid);

% Clear all variables
clear all
sprintf('%s','End')