# Earthquake Data Sonifier

Interactive earthquake visualization and sonification system built with Processing and Pure Data.

## Project Overview

This project creates an audiovisual representation of earthquake data, combining real-time visualization in Processing with sound synthesis in Pure Data. Users can explore historical earthquake data through both visual and auditory dimensions.

## Features

- **Real-time Data Playback**: Sequential visualization of earthquake events
- **Interactive Mode**: Click, drag, and modify earthquake parameters
- **Sound Mapping**:
  - Magnitude → Volume/Amplitude
  - Depth → Pitch (frequency)
  - Longitude → Stereo Panning
  - Tsunami events → Bass percussion hit
- **World Map Background**: Geographic context with simplified continents
- **Dynamic Envelopes**: Sound fades naturally after each event

## Technologies

- **Processing**: Visualization and data handling
- **Pure Data (PD)**: Audio synthesis and sonification
- **UDP Communication**: Data transmission between Processing and PD

## Installation

### Prerequisites
- Processing 4.x
- Pure Data (Vanilla)
- Libraries: oscP5, netP5 (for Processing)

### Setup
1. Clone this repository
2. Open `earthquake_sonifier/earthquake_sonifier.pde` in Processing
3. Open `earthquake_sonifier.pd` in Pure Data
4. Run Pure Data first (turn on audio: Media → Audio ON)
5. Then run the Processing sketch

## Controls

### Playback Mode
- **SPACE**: Pause/Resume
- **I**: Jump to interactive mode
- **R**: Restart from beginning
- **+/-**: Adjust playback speed
- **M**: Toggle world map

### Interactive Mode
- **Click**: Re-play earthquake sound
- **Drag**: Move earthquake and hear real-time updates
- **W/S**: Increase/Decrease magnitude
- **A/D**: Decrease/Increase depth
- **T**: Toggle tsunami flag

## Data

The project uses `earthquakes_clean_for_processing.csv` with the following columns:
- `date_time`: Event timestamp
- `magnitude`: Earthquake magnitude (Richter scale)
- `depth`: Depth in kilometers
- `latitude`: Geographic latitude
- `longitude`: Geographic longitude
- `sig`: Significance score
- `tsunami`: Tsunami flag (0 or 1)

## Project Structure

```
earthquake_sonifier/
├── earthquake_sonifier.pde      # Main Processing sketch
├── earthquakes_clean_for_processing.csv  # Dataset
earthquake_sonifier.pd            # Pure Data patch
earthquake_sonifier_simple.pd     # Simple test patch
```

## Sound Design

The sonification maps earthquake data to audible parameters:

- **Oscillator tone**: Represents the main earthquake event
- **Frequency**: Inverse relationship with depth (shallow = high pitch)
- **Amplitude envelope**: Attack-decay based on magnitude
- **Duration**: Longer sounds for stronger earthquakes (500-2000ms)
- **Noise bass**: Special low-frequency hit for tsunami events

## Author

Created for Interactive Systems university project.

## License

Educational project - 2025
