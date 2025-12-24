# ThreeToTwo Plugin - 3D to 2D Tool

## Overview

ThreeToTwo is a Godot Engine plugin specifically designed for rendering 3D models into 2D textures (3D to 2D). The plugin provides complete functionality for 3D model import, preview, editing, and export, making it particularly suitable for converting character, prop, and other resources from 3D to 2D in game development.

### Key Features

- **3D Model Import** - Supports mainstream 3D formats including FBX, GLTF, GLB, OBJ
- **Real-time Preview** - View 3D model rendering effects in real-time within the plugin window
- **Camera Control** - Supports mouse and keyboard camera view control
- **Lighting Control** - Adjust ambient and directional light with control mode switching
- **Material Switching** - Switch between regular and normal materials
- **Animation Control** - Play and control 3D model animations
- **Texture Export** - Render 3D models as 2D textures for export
- **Batch Export** - Export animation frames at specified time intervals
- **Multi-language Support** - Supports both Chinese and English interfaces

## Installation Guide

### Method 1: Direct Copy (Recommended)

1. Copy the `addons/threeToTwo` folder to your Godot project's `addons` directory
2. If your project doesn't have an `addons` directory, create it first
3. Open the Godot editor and go to **Project Settings**
4. Select the **Plugins** tab
5. Find the **ThreeToTwo** plugin and enable it

### Method 2: Through Godot Asset Library

1. Open the **AssetLib** in the Godot editor
2. Search for "ThreeToTwo" or "三渲二"
3. Download and install the plugin
4. Enable ThreeToTwo in the plugin settings

## Quick Start

### Step 1: Open the Plugin Window

1. After enabling the plugin, a **"3D To 2D"** button will appear in the Godot editor toolbar
2. Click this button to open the ThreeToTwo main window

### Step 2: Import 3D Model

1. Click the **"Upload Model"** button in the main window
2. Select your 3D model file (supports FBX, GLTF, GLB, OBJ formats)
3. Wait for the model import to complete

### Step 3: Adjust Model and Camera

1. Use mouse to control the camera:
   - **Middle button drag**: Rotate camera
   - **Right button drag**: Pan camera
   - **Mouse wheel**: Zoom camera
2. Use input fields to precisely adjust model position, rotation, and scale

### Step 4: Preview and Export

1. Click the **"Preview"** button to open the preview panel
2. Adjust texture size and material in the preview panel
3. Click the corresponding export buttons to export textures

## Interface Details

### Main Window Layout

The main window is divided into the following main areas:

#### 1. Toolbar Area
- **Preview Button**: Opens the preview panel
- **Upload Model Button**: Imports 3D model files
- **Language Selector**: Switches interface language (Chinese/English)

#### 2. Camera Control Area
- **Position Control**: X, Y, Z coordinate input fields
- **Rotation Control**: X, Y, Z rotation angle input fields
- **Reset Camera Button**: Restores camera to initial position

#### 3. Model Control Area
- **Position Control**: Model X, Y, Z coordinate input fields
- **Rotation Control**: Model X, Y, Z rotation angle input fields
- **Scale Control**: Model X, Y, Z scale factor input fields
- **Uniform Scale Checkbox**: Enables/disables uniform scaling mode

#### 4. Ambient Light Control
- **Ambient Light Intensity Input**: Adjusts scene ambient light brightness

#### 5. Directional Light Control Area
- **Light Toggle Checkbox**: Enables/disables directional light
- **Light Intensity Input**: Adjusts directional light brightness
- **Control Light Checkbox**: Switches between camera and light control modes

#### 6. Animation Control Area
- **Play/Pause Button**: Controls animation playback
- **Time Slider**: Drag to adjust animation progress
- **Loop Checkbox**: Enables/disables animation loop playback
- **Previous/Next Frame Buttons**: Frame-by-frame animation control

### Preview Panel Layout

The preview panel provides texture preview and export functionality:

#### 1. Preview Area
- **Texture Display**: Shows the currently rendered 2D texture
- **Zoom Control**: Supports mouse wheel zoom and drag viewing

#### 2. Control Toolbar
- **Close Button**: Closes the preview panel
- **Zoom Buttons**: Zoom in, zoom out, reset zoom
- **Zoom Percentage Input**: Precise control of zoom percentage

#### 3. Size Control
- **Width Input**: Sets texture width (pixels)
- **Height Input**: Sets texture height (pixels)

#### 4. Material Control
- **Material Selector**: Switches between regular and normal materials
- **Export Button Group**:
  - **Export Current Texture**: Exports the currently displayed texture
  - **Export Regular Texture**: Switches to regular material and exports
  - **Export Normal Texture**: Switches to normal material and exports
  - **Export Both Materials**: Exports both regular and normal textures simultaneously

#### 5. Animation Control
- **Animation Selector**: Selects animation to preview
- **Playback Control**: Play/pause, previous frame, next frame
- **Loop Checkbox**: Enables/disables animation looping

#### 6. Batch Export
- **Interval Time Input**: Sets time interval for batch export (seconds)
- **Batch Export Button**: Starts batch export of animation frames

#### 7. Interpolation Algorithm
- **Algorithm Selector**: Selects image scaling interpolation algorithm
  - **Nearest**: Nearest-neighbor interpolation (pixelated effect)
  - **Bilinear**: Bilinear interpolation (smooth effect)
  - **Cubic**: Cubic interpolation (smoother)
  - **Lanczos**: Lanczos interpolation (high quality)

## Detailed Function Usage

### 1. Model Import

#### Supported File Formats
- FBX (.fbx)
- GLTF (.gltf)
- GLB (.glb)
- OBJ (.obj)

#### Import Process
1. Click the **"Upload Model"** button
2. Select 3D model file in the file dialog
3. The plugin automatically handles the import process:
   - Checks if the model is already imported
   - If not imported, automatically copies file to project directory
   - Waits for Godot to complete model import
   - Loads model into preview scene

#### Notes
- First-time import of certain formats may take longer
- Please be patient when importing large model files
- Ensure model file paths don't contain Chinese characters or special characters

### 2. Camera Control

#### Mouse Control
- **Middle button drag**: Rotate camera view
- **Right button drag**: Pan camera position
- **Mouse wheel**: Zoom in/out view

#### Keyboard Control
- **W/S**: Move camera up/down
- **A/D**: Move camera left/right
- **Q/E**: Move camera forward/backward
- **Numpad 8/2**: Pitch rotation (look up/down)
- **Numpad 4/6**: Yaw rotation (look left/right)

#### Precise Control
Use input fields to precisely set camera position and rotation angles:
- **Position X/Y/Z**: Camera position in world coordinates
- **Rotation X/Y/Z**: Camera rotation angles (degrees)

#### Reset Function
Click the **"Reset Camera"** button to restore camera to initial position and angle.

### 3. Model Control

#### Position Adjustment
- Enter X, Y, Z coordinate values in the **Model Position** input fields
- Supports fine-tuning with up/down arrow keys (adjust step size with Shift/Ctrl keys)

#### Rotation Adjustment
- Enter X, Y, Z rotation angles (degrees) in the **Model Rotation** input fields
- Angle values are converted to radians in real-time and applied to the model

#### Scale Adjustment
- Enter X, Y, Z scale factors in the **Model Scale** input fields
- **Uniform Scale Mode**: When checked, modifying any axis scale automatically synchronizes other axes
- Default scale factor is 1.0 (original size)

#### Input Field Fine-tuning Tips
- **Direct Input**: Enter values in input fields and press Enter or click elsewhere
- **Arrow Key Fine-tuning**:
  - **Up/Down arrows**: Adjust by 0.1 step
  - **Shift + Up/Down arrows**: Adjust by 1.0 step
  - **Ctrl + Up/Down arrows**: Adjust by 0.01 step

### 4. Ambient Light Control

#### Light Intensity Adjustment
- Enter brightness value in the **Ambient Light Intensity** input field
- Value range: 0.0 (completely dark) to 10.0 (very bright)
- Default value: 1.0

#### Effect Description
- Ambient light affects the brightness of the entire scene
- Adjusting ambient light can change the brightness/darkness of textures
- Recommended to adjust based on model material and desired effect

### 5. Animation Control

#### Animation Playback
1. After importing a model with animations, available animation list appears in **Animation Selector**
2. Select animation to play
3. Click **Play** button to start animation playback
4. Use **Pause** button to pause playback

#### Progress Control
- **Time Slider**: Drag slider to jump to any time point in the animation
- **Time Input Field**: Enter precise time value (seconds) to position animation
- **Previous/Next Frame Buttons**: Control frame-by-frame with 0.01 second steps

#### Loop Playback
- Check **Loop** checkbox to automatically restart animation when it ends
- Uncheck to play once and stop

#### Animation Export
In the preview panel, you can export any frame of animation as a texture.

### 6. Preview Panel Usage

#### Opening Preview
1. Adjust model and camera position in the main window
2. Click the **"Preview"** button to open the preview panel
3. The preview panel displays the 2D texture from the current view

#### Texture Zoom
- **Mouse wheel**: Zoom in/out texture
- **Zoom buttons**: Zoom in, zoom out, reset zoom
- **Zoom input field**: Enter percentage for precise control (e.g., 150% means 1.5x zoom)
- **Middle button drag**: Drag to view different parts of texture (when zoomed in)

#### Size Settings
- **Width**: Sets exported texture width (pixels)
- **Height**: Sets exported texture height (pixels)
- Preview texture updates in real-time when size is modified

#### Material Switching
- **Regular Material**: Displays model's original material effect
- **Normal Material**: Displays model's normal map effect (for special rendering)
- Preview texture updates immediately when switching materials

### 7. Texture Export

#### Single Export
1. Adjust texture size and material in the preview panel
2. Click the corresponding export button:
   - **Export Current Texture**: Exports currently displayed texture
   - **Export Regular Texture**: Switches to regular material and exports
   - **Export Normal Texture**: Switches to normal material and exports
   - **Export Both Materials**: Exports both regular and normal textures simultaneously
3. Select save location and filename in the file dialog
4. Texture will be saved in PNG format

#### Export Settings
- **Automatic Filename Generation**: Automatically generates filenames based on animation name and export sequence number
- **Fixed Format**: Always exports as PNG format, supports alpha channel
- **Size Preservation**: Maintains size set during preview

### 8. Batch Export

#### Batch Export Process
1. Set time interval (seconds) in the **Batch Export** area of the preview panel
2. Click the **"Batch Export"** button
3. Select save directory and filename prefix in the file dialog
4. The plugin automatically:
   - Creates directory named with filename prefix
   - Creates "Regular Textures" and "Normal Textures" subdirectories
   - Exports each frame of animation at specified time intervals
   - Saves regular material and normal material textures separately

#### Batch Export Settings
- **Time Interval**: Time interval between exported frames (seconds)
  - Example: Set to 0.5 means export every 0.5 seconds
  - Set to 1.0 means export every second
- **Export Range**: All frames from animation start to end
- **File Naming**: `prefix_sequence.png` and `prefix_Normal_sequence.png`

#### Batch Export Uses
- Creating sprite animations
- Creating animation sequence frames
- Generating character action resources
- Creating special effect sequence images

### 9. Interpolation Algorithm Selection

#### Available Interpolation Algorithms
1. **Nearest (Nearest-neighbor)**
   - Effect: Pixelated, maintains hard edges
   - Suitable for: Pixel art, retro style
   - Performance: Fastest

2. **Bilinear**
   - Effect: Smooth, medium quality
   - Suitable for: General purpose, balances quality and performance
   - Performance: Faster

3. **Cubic**
   - Effect: Smoother, high quality
   - Suitable for: Scenarios requiring high-quality scaling
   - Performance: Slower

4. **Lanczos**
   - Effect: Highest quality, sharp and clear
   - Suitable for: Professional use, requires best quality
   - Performance: Slowest

#### Selection Recommendations
- Small texture enlargement: Use **Lanczos** or **Cubic** to maintain clarity
- Large texture reduction: Use **Bilinear** to balance quality and performance
- Pixel art style: Use **Nearest** to maintain pixel feel
- General game resources: Use **Bilinear** or **Cubic**

### 10. Directional Light Control

#### Light Toggle
- Check the **"Light"** checkbox to enable directional light
- Uncheck to disable directional light
- The directional light affects the scene's lighting and shadows

#### Light Intensity Adjustment
- Enter brightness value in the **"Light Intensity"** input field
- Value range: 0.0 (no light) to 16.0 (very bright)
- Default value: 1.0

#### Control Mode Switching
- Check the **"Control Light"** checkbox to switch to light control mode
- In light control mode:
  - Interface labels change from "Camera" to "Light"
  - Mouse middle button drag rotates the light instead of the camera
  - Input fields control light position and rotation instead of camera
- Uncheck to return to camera control mode

#### Light Rotation Control
- In light control mode, use mouse middle button drag to rotate the light
- Use input fields to precisely set light position and rotation angles
- Click the **"Reset"** button to restore light to initial position and rotation

## Advanced Features

### 1. Multi-language Support

The plugin supports both Chinese and English interfaces:
- Switch language in the main window's **Language Selector**
- All interface text updates immediately after switching
- Language settings are saved and maintained when reopening

### 2. Input Field Advanced Operations

#### Focus Management
- Click outside input fields to release all input field focus
- Camera keyboard control is temporarily disabled when input fields have focus
- Camera control automatically resumes when focus is lost

#### Value Fine-tuning
All numerical input fields support:
- Direct value input
- Up/down arrow key fine-tuning
- Step size adjustment with modifier keys
- Enter key to confirm input

### 3. Model Material System

#### Regular Material
- Uses model's original material
- Displays model's texture and color
- Suitable for most export needs

#### Normal Material
- Uses special normal shader
- Displays model's normal information
- Outputs RGB colors representing normal direction
- Used for special rendering effects or post-processing

#### Material Switching Principle
- When switching materials, the plugin applies corresponding material to all mesh instances
- In normal material mode, a normal mesh with purple background is displayed
- Switching process is fully automated, no manual operation required

### 4. Camera Parameter Configuration

In the camera control script, you can adjust the following parameters (requires code editing):

```gdscript
@export var rotationSpeed: float = 1.0      # Rotation speed
@export var zoomSpeed: float = 1.0          # Zoom speed
@export var panSpeed: float = 0.5           # Pan speed
@export var minZoom: float = 1.0            # Minimum zoom distance
@export var maxZoom: float = 20.0           # Maximum zoom distance
@export var autoRotateSpeed: float = 0.5    # Auto-rotate speed
@export var keyboardMoveSpeed: float = 1.0  # Keyboard move speed
@export var keyboardRotateSpeed: float = 0.1 # Keyboard rotate speed
@export var keyboardVerticalSpeed: float = 1.0 # Keyboard vertical speed
```

## Shortcut Reference

### Main Window Shortcuts

#### Camera Control
- **Middle mouse button drag**: Rotate camera
- **Right mouse button drag**: Pan camera
- **Mouse wheel**: Zoom camera
- **W/S**: Move camera up/down
- **A/D**: Move camera left/right
- **Q/E**: Move camera forward/backward
- **Numpad 8/2**: Pitch rotation
- **Numpad 4/6**: Yaw rotation

#### Input Field Operations
- **Enter key**: Confirm input
- **Up/Down arrows**: Adjust value by 0.1 step
- **Shift + Up/Down arrows**: Adjust value by 1.0 step
- **Ctrl + Up/Down arrows**: Adjust value by 0.01 step
- **Click outside**: Release input field focus

### Preview Panel Shortcuts

#### Texture Viewing
- **Mouse wheel**: Zoom texture
- **Middle mouse button drag**: Drag to view texture (when zoomed in)
- **Ctrl + Mouse wheel**: Fast zoom

#### Animation Control
- **Spacebar**: Play/pause animation
- **Left arrow**: Previous frame (0.01 second)
- **Right arrow**: Next frame (0.01 second)

## Frequently Asked Questions

### Q1: What to do when getting errors during model import?
**A:** Check the following:
1. Whether model file format is supported (FBX, GLTF, GLB, OBJ)
2. Whether model file path contains Chinese characters or special characters
3. Whether model file is corrupted
4. Whether Godot has corresponding model importers installed

### Q2: Exported texture size is incorrect?
**A:** Check:
1. Width and height settings in the preview panel
2. Whether size was modified before export but not confirmed by clicking elsewhere
3. Try clicking outside input fields or pressing Enter to confirm size

### Q3: Normal material appears purple?
**A:** This is normal:
1. Normal material uses special shader to render normal information
2. Purple background is the default color of the normal shader
3. When model has normal information, it displays as colored normal map
4. If model has no normal information, it maintains purple background

### Q4: Batch export gets stuck or stops?
**A:** Possible causes and solutions:
1. **Animation too long**: Reduce time interval or export range
2. **Texture size too large**: Reduce width and height settings
3. **Insufficient disk space**: Check available space in save directory
4. **File permission issues**: Ensure write permissions
5. **Try restarting plugin**: Close and reopen plugin window

### Q5: Plugin window won't open?
**A:** Try the following steps:
1. Check if plugin is properly enabled
2. Restart Godot editor
3. Check Godot version compatibility (recommended Godot 4.0+)
4. Check console for error messages

### Q6: How to adjust plugin window size?
**A:** Plugin window supports resizing:
1. Drag window edges or corners to resize
2. Minimum size is 800×600 pixels
3. Window size is automatically saved and maintained when reopening

### Q7: Exported textures have black borders or transparent areas?
**A:** This may be because:
1. **Incorrect model position**: Adjust model position to center in camera view
2. **Camera too far**: Reduce camera distance
3. **Model size too small**: Increase model scale factor
4. **Background settings**: Check environment settings for transparent background

## Technical Support

### Getting Help
If you encounter problems or need assistance:
1. **Check this documentation**: First consult relevant sections of this user manual
2. **Check console**: Godot editor's output panel may have error messages
3. **Contact developer**: Contact developer through plugin release page
4. **Community support**: Ask questions in Godot Chinese community or related forums

### Reporting Issues
When reporting issues, please provide the following information:
1. Godot version number
2. Plugin version number
3. Operating system and version
4. Detailed description of the problem
5. Steps to reproduce the issue
6. Relevant error messages or screenshots

### Changelog
Check the plugin's changelog for latest features and fixes.

## Conclusion

The ThreeToTwo plugin provides Godot developers with a powerful 3D to 2D tool, simplifying the conversion process from 3D models to 2D textures. Whether you're making 2D games needing character sprites, or need to convert 3D resources to 2D resources, this plugin can help you complete your work efficiently.

If you have any suggestions or feedback, please contact the developer. Enjoy using it!

---
*Last updated: December 2025*
*ThreeToTwo Plugin Development Team*
