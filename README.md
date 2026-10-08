# Ksp37-Expression-Quantification
Quantification of Ksp37 positive cells and mean Ksp37 expression

## Description
Segments cells based on membrane stain and compares mean Ksp37 signal in each cell to a manually set threshold to quantify the percentage of Ksp37+ cells. Saves a results table and outline image (JPEG) highlighting positive and negative cells.

## Requirements
- Fiji (ImageJ 1.54p; Java 21.0.7, 64-bit), macOS Tahoe 26.6.2
- Bio-Formats plugin (version 8.5.0), included in the default Fiji installation, used to open .nd2 files
- No additional plugins or update sites required

## Input format
- `.nd2` files (file type can be changed with `fileExtension`)
- Channel 0: cell mask channel used for segmentation
- Channel 1: Ksp37 staining
- Other channels are ignored. Files without channels 0 and 1 are skipped.

## How to run
Open Fiji → Plugins → Macros → Run… → select the .ijm file → choose the input folder with the images → choose the output folder.
The results table is saved in the output folder, and a subfolder `Segmentation` is created for the outline images.

## Segmentation (fixed in the script)
- Background subtraction, channel 0: rolling ball radius 60.
- Gaussian blur (sigma 2), then Huang auto-threshold and Analyze Particles with a minimum size of 20 (calibrated units).
- Scale bar: 20 µm, requires calibrated images.

## User parameters
- `bgRolling1`: rolling ball radius for background subtraction of channel 1 (Ksp37). Set to 8 to remove cytoplasmic background while avoiding loss of true Ksp37 signal.
- `signalThreshold_Ksp37`: mean Ksp37 value (after background subtraction) above which a cell is counted as positive. Applied equally to all images. Set manually based on the background stain and signal intensity.
- `colorPositive`, `colorNegative`: outlines colors for Ksp37 positive and negative cells in the JPEG.
- `displayMin` and `displayMax`: display range of the Ksp37 image in the JPEG, adjust to signal intensity. Does not affect quantification.
- `fileExtension`: file type to process in the input folder.

## Outputs
- `Ksp37_Results.csv`: one row per image. Re-running on the same output folder adds new images and overwrites rows of images analysed before.
- `Segmentation/<image>_Ksp37_outlines.jpg`: one outline image per image.

CSV columns:
- `Image_Name`
- `N_cells`: total number of cells detected
- `N_Ksp37_positive`: number of Ksp37 positive cells
- `Pct_Ksp37_positive`: percentage of Ksp37 positive cells
- `Mean_Ksp37_intensity_positive`: mean of the per-cell mean Ksp37 intensities of positive cells
- `bgRolling1`, `signalThreshold_Ksp37`, `displayMin`, `displayMax`: parameter values used when running the macro

## License
MIT

## Cite
LINK TO PAPER ONCE AVAILABLE
