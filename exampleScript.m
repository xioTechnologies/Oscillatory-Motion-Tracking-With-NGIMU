clc
clear
close all;

%% Import data

sessionData = importSession('OscillatoryMotionTrackingSession');

samplePeriod = 1 / 200; % 200 Hz
[sessionData, time] = resampleSession(sessionData, samplePeriod); % resample data so that all measuremnts share the same time vector

quaternion = sessionData.(sessionData.deviceNames{1}).quaternion.vector;
acceleration = sessionData.(sessionData.deviceNames{1}).earth.vector * 9.81; % convert to m/s/s

numberOfSamples = length(time);

%% Calculate velocity

velocity = zeros(size(acceleration));
for sampleIndex = 2 : numberOfSamples
    velocity(sampleIndex, :) = velocity(sampleIndex - 1, :) + acceleration(sampleIndex, :) * samplePeriod;
end

%% High-pass filter velocity to remove drift

cutoffFrequency = 0.5; % Hz
[b, a] = butter(1, cutoffFrequency / (1 / samplePeriod) / 2, 'high'); % 1st order filter
velocity = filtfilt(b, a, velocity); % zero-phase filter

%% Calculate position

position = zeros(size(velocity));
for sampleIndex = 2 : numberOfSamples
    position(sampleIndex, :) = position(sampleIndex - 1, :) + velocity(sampleIndex, :) * samplePeriod;
end

%% High-pass filter position to remove drift

cutoffFrequency = 0.5; % Hz
[b, a] = butter(1, cutoffFrequency / (1 / samplePeriod) / 2, 'high'); % 1st order filter
position = filtfilt(b, a, position); % zero-phase filter

%% Plot data

figure;

subplots(1) = subplot(3, 1, 1);
hold on;
plot(time, acceleration(:, 1), 'r');
plot(time, acceleration(:, 2), 'g');
plot(time, acceleration(:, 3), 'b');
title('Acceleration');
xlabel('seconds)');
ylabel('m/s/s');
legend('x', 'y', 'z');

subplots(2) = subplot(3, 1, 2);
hold on;
plot(time, velocity(:, 1), 'r');
plot(time, velocity(:, 2), 'g');
plot(time, velocity(:, 3), 'b');
title('Velocity');
xlabel('seconds)');
ylabel('m/s');
legend('x', 'y', 'z');

subplots(3) = subplot(3, 1, 3);
hold on;
plot(time, position(:, 1), 'r');
plot(time, position(:, 2), 'g');
plot(time, position(:, 3), 'b');
title('Position');
xlabel('seconds)');
ylabel('m');
legend('x', 'y', 'z');

linkaxes(subplots, 'x');

%% Create animation

SixDofAnimation(position, quatern2rotMat(quaternion), ...
                'SamplePlotFreq', 20, ...
                'Position', [9 39 1280 768], ...
                'AxisLength', 0.1, 'ShowArrowHead', false, ...
                'Xlabel', 'X (m)', 'Ylabel', 'Y (m)', 'Zlabel', 'Z (m)', 'ShowLegend', false);
