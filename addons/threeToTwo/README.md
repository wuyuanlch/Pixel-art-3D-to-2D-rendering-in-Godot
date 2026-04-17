# threeToTwo Plugin - Godot 3D to 2D Tool

## Overview

threeToTwo is a Godot Engine plugin specifically designed for rendering 3D models as 2D textures (3D to 2D). The plugin features a completely new architecture that deeply integrates with the Godot Editor, leveraging the editor's native functionality to provide an efficient and flexible 3D to 2D workflow.

### Design Philosophy

Unlike traditional standalone window plugins, threeToTwo adopts an **Editor Integration** design philosophy:
- **Leverage Godot Native Features**: Model movement, rotation, scaling, and lighting setup are performed directly in the Godot Editor
- **Right Dock Panel**: Serves as an editor extension, providing specialized 3D to 2D functionality
- **Real-time Synchronization**: Interacts with the editor scene in real-time, WYSIWYG
- **Multi-model Management**: Supports managing multiple models and animations simultaneously

### Key Features

- **3D Model Import** - Supports mainstream 3D formats like FBX, GLTF, GLB, OBJ with automatic import processing
- **Camera Management** - Select cameras from the scene, real-time camera transform synchronization, scene camera following
- **AnimationPlayer Manager** - Batch add and control multiple AnimationPlayers, unified animation playback management
- **Real-time Preview** - View 3D model rendering effects in real-time within the plugin panel
- **Material Switching** - Switch between normal and normal map materials to meet different rendering needs
- **Effect Texture Caching** - Capture animation sequences to generate effect textures for VFX production
- **Texture Export** - Export 3D models as 2D textures, supporting single frame and batch export
- **Camera Configuration** - Save and load camera configuration files for quick workflow restoration

## Installation Guide

### Method 1: Direct Copy (Recommended)

1. Copy the `addons/threeToTwo` folder to your Godot project's `addons` directory
2. If there is no `addons` directory in your project, create it first
3. Open the Godot Editor, go to **Project Settings**
4. Select the **Plugins** tab
5. Find the **threeToTwo** plugin and enable it

### Method 2: Via Git Submodule

```bash
# In your Godot project directory
git submodule add https://github.com/wuyuanlch/3DTo2D.git addons/threeToTwo
```

After enabling the plugin, a **3Dto2D** dock panel will appear on the right side of the Godot Editor.

## Quick Start

### Step 1: Scene Setup

1. Create or open a 3D scene in the Godot Editor
2. Add a Camera3D node as the rendering camera
3. Add a Node3D node as a model container (optional)
4. Add AnimationPlayer nodes and set up animations (optional)

### Step 2: Using the Plugin Panel

1. After enabling the plugin, the **3Dto2D** panel will appear in the right dock
2. Click the **"Get Selected Camera"** button to select a Camera3D node from the scene
3. Click the **"Get Selected ModelContainer"** button to select a model container node
4. Click the **"Get Selected AnimationPlayer"** button to add AnimationPlayers to the manager

### Step 3: Preview and Export

1. Click the **"Image and Animation Export"** button to open the preview panel
2. Adjust texture size and material in the preview panel
3. Click the corresponding export buttons to export textures

## Interface Details

### Right Dock Panel Layout

The main plugin interface is located in the Godot Editor's right dock panel, divided into the following main areas:

#### 1. Camera Management Area
- **Camera Label**: Displays the name of the currently selected camera node
- **"Get Selected Camera" Button**: Selects a Camera3D node from the scene
- **Real-time Sync Checkbox**: Enables/disables real-time camera transform synchronization
- **Scene Follow Checkbox**: Enables/disables scene camera following mode

#### 2. Model Container Area
- **Model Container Label**: Displays the name of the currently selected model container node
- **"Get Selected ModelContainer" Button**: Selects a Node3D node from the scene as a model container
- **"Upload Model to Container" Button**: Uploads 3D model files to the selected container

#### 3. AnimationPlayer Manager Area
- **"Get Selected AnimationPlayer" Button**: Adds selected AnimationPlayers to the manager
- **AnimationPlayer List**: Displays all added AnimationPlayers
- **Control Button Group**:
  - **"Play All"**: Plays all selected AnimationPlayers
  - **"Pause All"**: Pauses all selected AnimationPlayers
  - **"Stop All"**: Stops all selected AnimationPlayers

#### 4. Function Button Area
- **"Image and Animation Export" Button**: Opens the preview panel
- **"Cache Effects" Button**: Starts/stops effect texture caching
- **"Load Camera Config" Button**: Loads camera configuration files

### AnimationPlayer Entry

Each AnimationPlayer added to the manager displays an entry containing:
- **Animation Name Label**: Displays the AnimationPlayer node name
- **Animation Selection Dropdown**: Selects the animation to play
- **Play/Pause Button**: Controls the playback state of that AnimationPlayer
- **Selection Checkbox**: Enables/disables the AnimationPlayer's participation in global control
- **Loop Checkbox**: Enables/disables animation loop playback
- **Remove Button**: Removes the AnimationPlayer from the manager

### Preview Panel Layout

Click the **"Image and Animation Export"** button to open the preview panel, providing texture preview and export functionality:

#### 1. Preview Area
- **Texture Display**: Displays the currently rendered 2D texture
- **Zoom Control**: Supports mouse wheel zoom and drag viewing

#### 2. Control Toolbar
- **Close Button**: Closes the preview panel
- **Zoom Buttons**: Zoom in, zoom out, reset zoom
- **Zoom Percentage Input**: Precise zoom control

#### 3. Size Control
- **Width Input**: Sets texture width (pixels)
- **Height Input**: Sets texture height (pixels)

#### 4. Material Control
- **Material Selector**: Switches between normal and normal map materials
- **Export Button Group**:
  - **Export Current Texture**: Exports the currently displayed texture
  - **Export Normal Texture**: Switches to normal material and exports
  - **Export Normal Map**: Switches to normal map material and exports
  - **Export Both Materials**: Exports both normal and normal map textures

#### 5. Animation Control
- **Time Slider**: Drag to adjust animation progress
- **Play/Pause Button**: Controls animation playback
- **Previous/Next Frame Buttons**: Frame-by-frame control
- **Frame Info Label**: Displays current time/total duration

#### 6. Batch Export
- **Interval Time Input**: Sets time interval for batch export (seconds)
- **Batch Export Button**: Starts batch export of animation frames

#### 7. Interpolation Algorithm
- **Algorithm Selector**: Selects image scaling interpolation algorithm
  - **Nearest**: Nearest-neighbor interpolation (pixelated effect)
  - **Bilinear**: Bilinear interpolation (smooth effect)
  - **Cubic**: Cubic interpolation (smoother)
  - **Lanczos**: Lanczos interpolation (highest quality)

### VFX Preview Panel Layout

After clicking the **"Cache Effects"** button, the VFX preview panel pops up:

#### 1. Preview Area
- **Texture Sequence Display**: Displays cached texture sequences
- **Playback Control**: Play/pause texture sequence

#### 2. Material Parameter Control
- **Threshold Slider**: Adjusts material threshold (0.0-1.0)
- **Softness Slider**: Adjusts material edge softness (0.0-0.5)
- **Background Color Picker**: Selects background color

#### 3. Export Control
- **Export Button**: Exports the currently displayed texture

## Feature Usage Details

### 1. Camera Management

#### Selecting a Camera
1. Select a Camera3D node in the scene
2. Click the **"Get Selected Camera"** button in the plugin panel
3. The camera name will display in the camera label

#### Real-time Synchronization
- When **Real-time Sync Checkbox** is enabled, the selected camera's transforms synchronize in real-time to the preview viewport
- When moving/rotating the camera in the Godot Editor, the preview updates in real-time
- When disabled, camera transforms don't automatically synchronize

#### Scene Camera Following
- When **Scene Follow Checkbox** is enabled, the selected camera follows the editor scene camera
- When moving the view in the 3D editor, the selected camera also moves synchronously
- Suitable for scenarios where you need to preview rendering effects from the editor's perspective

### 2. Model Container Management

#### Selecting a Model Container
1. Select a Node3D node (or any 3D node) in the scene
2. Click the **"Get Selected ModelContainer"** button in the plugin panel
3. The container name will display in the model container label

#### Uploading Models
1. First select a model container node
2. Click the **"Upload Model to Container"** button
3. Select a 3D model file in the file dialog (supports FBX, GLTF, GLB, OBJ)
4. The plugin automatically handles the import process:
   - Checks if the model is already imported
   - If not imported, automatically copies the file to the project directory
   - Waits for Godot to complete model import
   - Loads the model into the selected container

### 3. AnimationPlayer Manager

#### Adding AnimationPlayers
1. Select an AnimationPlayer node in the scene
2. Click the **"Get Selected AnimationPlayer"** button
3. The AnimationPlayer will be added to the manager and displayed as an entry

#### Managing Multiple Animations
- Multiple AnimationPlayers can be added to the manager
- Each AnimationPlayer can independently select animations and control playback
- Use the **Selection Checkbox** to control which AnimationPlayers participate in global control

#### Global Control
- **"Play All"**: Plays all selected AnimationPlayers
- **"Pause All"**: Pauses all selected AnimationPlayers
- **"Stop All"**: Stops all selected AnimationPlayers

#### Animation Synchronization
- All selected AnimationPlayers play synchronously
- When controlling time in the preview panel, all animations synchronize to the same time point
- Supports both loop and non-loop modes

### 4. Real-time Preview

#### Opening Preview
1. After setting up the camera and models, click the **"Image and Animation Export"** button
2. The preview panel displays the rendering result from the current camera perspective
3. The preview image automatically adjusts according to the set size

#### Preview Interaction
- **Mouse Wheel**: Zoom preview image
- **Middle Mouse Button Drag**: Drag to view different parts of the image when zoomed in
- **Zoom Buttons**: Zoom in, zoom out, reset zoom ratio
- **Zoom Input**: Input percentage for precise zoom control

### 5. Material Switching

#### Normal Material
- Displays the model's original material effect
- Suitable for most export needs
- Preserves the model's texture and color information

#### Normal Map Material
- Uses a special normal shader for rendering
- Displays the model's normal information
- Outputs RGB colors representing normal direction
- Used for special rendering effects or post-processing

#### Switching Effects
- After switching materials, the preview updates immediately
- All model meshes simultaneously apply the new material
- In normal map mode, a purple-background normal mesh is displayed

### 6. Texture Export

#### Single Export
1. Adjust texture size and material in the preview panel
2. Click the corresponding export button:
   - **Export Current Texture**: Exports the currently displayed texture
   - **Export Normal Texture**: Switches to normal material and exports
   - **Export Normal Map**: Switches to normal map material and exports
   - **Export Both Materials**: Exports both normal and normal map textures
3. Select save location and filename in the file dialog
4. Textures are saved in PNG format

#### Export Settings
- **Automatic Filename Generation**: Automatically generates filenames based on animation name and export sequence number
- **Fixed Format**: Always exports as PNG format, supporting alpha channel
- **Size Preservation**: Maintains the size set during preview

### 7. Animation Control

#### Playback Control
1. In the preview panel, use the time slider or input box to set the time
2. Click the **Play** button to start animation playback
3. Click the **Pause** button to pause playback
4. Use **Previous/Next Frame** buttons for frame-by-frame control

#### Time Synchronization
- All selected AnimationPlayers synchronize to the same time point
- Supports both loop and non-loop playback
- Time slider displays current time/total duration

### 8. Batch Export

#### Batch Export Process
1. Set the time interval (seconds) in the **Batch Export** area of the preview panel
2. Click the **"Batch Export"** button
3. Select save directory and filename prefix in the file dialog
4. The plugin automatically:
   - Creates a directory named with the filename prefix
   - Creates "Normal Textures" and "Normal Map Textures" subdirectories
   - Exports each frame of the animation at the set time interval
   - Saves normal and normal map material textures separately

#### Batch Export Settings
- **Time Interval**: Time interval between exported frames (seconds)
  - Example: Setting to 0.5 exports one frame every 0.5 seconds
  - Setting to 1.0 exports one frame per second
- **Export Range**: All frames from animation start to end
- **File Naming**: `prefix_sequence.png` and `prefix_Normal_sequence.png`

### 9. Effect Texture Caching

#### Caching Process
1. Click the **"Cache Effects"** button in the plugin panel
2. The plugin automatically:
   - Plays all selected animations
   - Captures textures at fixed intervals (0.01 seconds)
   - Caches textures for the entire animation sequence
3. After caching completes, the VFX preview panel automatically pops up

#### VFX Preview Panel
- Displays cached texture sequences
- Supports play/pause of texture sequences
- Allows adjustment of material parameters (threshold, softness, background color)
- Allows export of currently displayed textures

#### Application Scenarios
- Creating effect sequence images
- Generating particle system textures
- Creating dynamic texture resources

### 10. Camera Configuration Files

#### Saving Camera Configuration
Camera configurations can be saved via code, including:
- Camera position, rotation, scale
- Camera properties (FOV, near plane, far plane)
- Export size settings

#### Loading Camera Configuration
1. Click the **"Load Camera Config"** button
2. Select a camera configuration file (JSON format)
3. The plugin automatically:
   - Applies camera position and rotation
   - Updates the preview panel's size settings
   - Restores the working state

#### Configuration File Format
```json
{
  "version": "1.0",
  "camera": {
    "position": {"x": 0, "y": 0, "z": 5},
    "rotation": {"x": 0, "y": 0, "z": 0, "w": 1},
    "fov": 70,
    "near": 0.1,
    "far": 100,
    "scale": {"x": 1, "y": 1, "z": 1}
  },
  "export_size": {
    "width": 512,
    "height": 512
  }
}
```

### 11. Interpolation Algorithm Selection

#### Available Interpolation Algorithms
1. **Nearest (Nearest-neighbor)**
   - Effect: Pixelated, maintains hard edges
   - Use Case: Pixel art, retro style
   - Performance: Fastest

2. **Bilinear**
   - Effect: Smooth, medium quality
   - Use Case: General purpose, balances quality and performance
   - Performance: Fast

3. **Cubic**
   - Effect: Smoother, high quality
   - Use Case: Scenarios requiring high-quality scaling
   - Performance: Slower

4. **Lanczos**
   - Effect: Highest quality, sharp and clear
   - Use Case: Professional use, requires best quality
   - Performance: Slowest

#### Selection Recommendations
- Small texture enlargement: Use **Lanczos** or **Cubic** to maintain clarity
- Large texture reduction: Use **Bilinear** to balance quality and performance
- Pixel art style: Use **Nearest** to maintain pixel feel
- General game resources: Use **Bilinear** or **Cubic**

## Advanced Features

### 1. Multiple AnimationPlayer Synchronization

#### Synchronization Principle
- All selected AnimationPlayers use the same global timeline
- Each AnimationPlayer plays its own selected animation
- Supports synchronization of animations with different lengths

#### Loop Handling
- If an animation is set to loop, it restarts when reaching the end
- Non-loop animations pause when reaching the end
- All animations have independent loop settings

### 2. Real-time Synchronization Mechanism

#### Synchronization Process
1. The plugin checks camera transforms in the `_process` function
2. If real-time sync is enabled, applies camera transforms to the preview viewport camera
3. Forces SubViewport rendering update

#### Performance Optimization
- Only updates when transforms change
- Uses caching to reduce unnecessary calculations
- Supports disabling real-time sync to improve performance

### 3. Model Import System

#### Automatic Import Process
1. Checks if the model is already imported (checks .import files)
2. If not imported, copies the file to the project directory
3. Waits for Godot to complete model import
4. Loads the model into the selected container

#### Import Optimization
- **Smart Detection**: Automatically detects if models are already imported to avoid duplicate imports
- **Asynchronous Processing**: Import process doesn't block the editor interface
- **Error Handling**: Provides detailed error information and recovery suggestions

### 4. Texture Caching System

#### Caching Mechanism
1. Captures textures at fixed time intervals (0.01 seconds)
2. Stores textures in memory arrays
3. Supports playback of cached texture sequences

#### Performance Considerations
- Cached textures consume memory, so it's recommended to clear them promptly
- Supports stopping caching midway
- Automatically pops up the preview panel after caching completes

## Frequently Asked Questions

### Q1: The plugin panel is not showing up. What should I do?
**A:** Check the following:
1. Whether the plugin is correctly enabled (Project Settings → Plugins)
2. Whether you've restarted the Godot Editor
3. Check the console for any error messages
4. Ensure Godot version compatibility (recommended Godot 4.0+)

### Q2: Unable to select camera or model container?
**A:** Confirm:
1. You've selected the correct node types in the scene
   - Camera: Must be a Camera3D node
   - Model container: Can be any Node3D node
2. The node is in the scene tree and valid
3. Try reselecting the node

### Q3: Preview panel shows blank or errors?
**A:** Possible reasons:
1. No valid camera node selected
2. Camera not properly set up
3. Model not within camera view
4. Real-time synchronization disabled

### Q4: Exported texture size is incorrect?
**A:** Check:
1. Width and height settings in the preview panel
2. Whether you modified the size but didn't confirm before exporting
3. Try clicking outside the input box or pressing Enter to confirm the size

### Q5: Normal map material shows as purple?
**A:** This is normal:
1. Normal map material uses a special shader to render normal information
2. Purple background is the default color of the normal shader
3. When the model has normal information, it displays as a colored normal map
4. If the model has no normal information, it remains with a purple background

### Q6: Animations not synchronized or playing abnormally?
**A:** Check:
1. Whether all AnimationPlayers have been correctly added to the manager
2. Whether AnimationPlayers are selected to participate in global control
3. Whether animations are set to loop playback
4. Whether the time slider is within the valid range

### Q7: Batch export gets stuck or stops?
**A:** Possible causes and solutions:
1. **Animation too long**: Reduce time interval or export range
2. **Texture size too large**: Reduce width and height settings
3. **Insufficient disk space**: Check available space in the save directory
4. **File permission issues**: Ensure write permissions
5. **Try restarting the plugin**: Close and reopen the plugin window

### Q8: Effect texture caching fails?
**A:** Confirm:
1. Whether there are selected AnimationPlayers
2. Whether animations can play normally
3. Whether there's sufficient memory
4. Try reducing the caching time interval

## Architecture Upgrade Explanation

### Main Differences from Previous Version

#### 1. Design Philosophy Upgrade
- **Previous Version**: Standalone window, reimplemented model, lighting, and camera controls
- **New Version**: Editor integration, leverages Godot native features, focuses on core 3D to 2D value

#### 2. Functional Focus Shift
- **Previous Version**: Emphasized controlling models and lighting within the plugin
- **New Version**: Emphasizes AnimationPlayer management, real-time synchronization, effect caching

#### 3. User Experience Improvements
- **More aligned with Godot workflow**: Operate in the editor, preview and export in the plugin
- **More efficient multi-model management**: Supports managing multiple AnimationPlayers simultaneously
- **More flexible camera control**: Real-time sync, scene following, configuration files

#### 4. Technical Architecture Optimization
- **Better performance**: Reduces unnecessary redraws, optimizes synchronization mechanism
- **Stronger extensibility**: Modular design, easy to add new features
- **More stable import system**: Smart detection, error recovery

### Upgrade Advantages

1. **More aligned with plugin design philosophy**: As an editor extension, not a standalone tool
2. **Higher efficiency**: Leverages existing editor functionality, reduces duplicate work
3. **Better compatibility**: Deep integration with Godot Editor, avoids compatibility issues
4. **Stronger functionality**: New features like AnimationPlayer manager, effect caching, etc.
5. **Better user experience**: More natural workflow, lower learning curve

## Technical Support

### Getting Help
If you encounter problems or need help:
1. **Check this documentation**: First consult the relevant sections of this user manual
2. **Check the console**: The Godot Editor's output panel may have error messages
3. **GitHub Issues**: Submit issue reports in the project repository
4. **Community Support**: Ask questions in Godot Chinese community or related forums

### Reporting Issues
When reporting issues, please provide the following information:
1. Godot version number
2. Plugin version number
3. Operating system and version
4. Detailed description of the problem
5. Steps to reproduce the problem
6. Relevant error messages or screenshots

### Contribution Guidelines
Contributions to code or documentation are welcome:
1. Fork the project repository
2. Create a feature branch
3. Commit your changes
4. Create a Pull Request

## Conclusion

The threeToTwo plugin provides Godot developers with a modern, efficient 3D to 2D tool that deeply integrates with the editor and fully utilizes Godot's native functionality. Whether you're making 2D games that require character sprites or need to convert 3D resources to 2D resources, this plugin can help you complete your work efficiently.

The new architecture design makes the plugin more stable, efficient, and user-friendly, representing best practices in Godot plugin development.

If you have any suggestions or feedback, please contact the developer via GitHub. Enjoy using it!

## License

This plugin is provided under the Apache License 2.0. See the LICENSE file for details.

---
*Last Updated: April 2026*
*Developer: WZY*
