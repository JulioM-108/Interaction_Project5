// Data Sonifier - Earthquakes
// Processing Sketch for earthquake visualization and sonification
// Sends data to Pure Data via UDP

import oscP5.*;
import netP5.*;
import java.net.*;

// UDP Configuration
OscP5 oscP5;
NetAddress pureData;
DatagramSocket udpSocket;
InetAddress pdAddress;

// Data
Table earthquakeData;
ArrayList<Earthquake> earthquakes;

// Sketch states
enum State {
  LOADING,
  PLAYING,
  INTERACTIVE
}

State currentState = State.LOADING;

// Playback control
int currentIndex = 0;
int playbackSpeed = 20; // frames between each earthquake (adjustable)
int frameCounter = 0;

// Interaction variables
Earthquake selectedEarthquake = null;
boolean dragging = false;
int lastSendFrame = 0;
int sendInterval = 5; // Send sound update every 5 frames when dragging

// Mapping configuration
float minMagnitude = 6.5;
float maxMagnitude = 9.0;
float minDepth = 10;
float maxDepth = 700;
float minSig = 600;
float maxSig = 1100;

// Visual configuration
PImage worldMap;
boolean useWorldMap = true;
boolean drawContinents = true;

void setup() {
  size(1200, 600);
  
  // Try to load world map image
  try {
    worldMap = loadImage("world_map.png");
    useWorldMap = true;
    println("World map image loaded successfully");
  } catch (Exception e) {
    println("No world_map.png found - will draw simplified continents");
    useWorldMap = false;
  }
  
  // Initialize UDP socket for Pure Data
  try {
    udpSocket = new DatagramSocket();
    pdAddress = InetAddress.getByName("127.0.0.1");
    println("UDP socket initialized - sending to Pure Data on port 3000");
  } catch (Exception e) {
    println("Error initializing UDP: " + e.getMessage());
  }
  
  // Load data
  earthquakes = new ArrayList<Earthquake>();
  loadEarthquakeData();
  
  println("Total earthquakes loaded: " + earthquakes.size());
  println("Press SPACE to pause/resume");
  println("Press 'I' to jump to interactive mode");
  println("Press 'R' to restart");
}

void draw() {
  background(0);
  
  // Draw world map background
  if (useWorldMap && worldMap != null) {
    tint(255, 120); // Semi-transparent
    image(worldMap, 0, 0, width, height);
    noTint();
  } else if (drawContinents) {
    drawSimplifiedWorld();
  }
  
  // Draw reference grid
  drawGrid();
  
  // State machine
  switch(currentState) {
    case LOADING:
      drawLoadingScreen();
      break;
      
    case PLAYING:
      updatePlayback();
      drawAllEarthquakes();
      drawPlaybackInfo();
      break;
      
    case INTERACTIVE:
      drawAllEarthquakes();
      drawInteractiveInfo();
      handleMouseInteraction();
      break;
  }
}

void loadEarthquakeData() {
  currentState = State.LOADING;
  
  try {
    earthquakeData = loadTable("earthquakes_clean_for_processing.csv", "header");
    
    println("Processing " + earthquakeData.getRowCount() + " rows...");
    
    for (TableRow row : earthquakeData.rows()) {
      String dateTime = row.getString("date_time");
      float magnitude = row.getFloat("magnitude");
      float depth = row.getFloat("depth");
      float latitude = row.getFloat("latitude");
      float longitude = row.getFloat("longitude");
      int sig = row.getInt("sig");
      int tsunami = row.getInt("tsunami");
      
      Earthquake eq = new Earthquake(dateTime, magnitude, depth, latitude, longitude, sig, tsunami);
      earthquakes.add(eq);
    }
    
    // Calculate actual data ranges for better mapping
    calculateDataRanges();
    
    // Start playback
    currentState = State.PLAYING;
    
  } catch (Exception e) {
    println("Error loading CSV file: " + e.getMessage());
    exit();
  }
}

void calculateDataRanges() {
  if (earthquakes.size() == 0) return;
  
  minMagnitude = maxMagnitude = earthquakes.get(0).magnitude;
  minDepth = maxDepth = earthquakes.get(0).depth;
  minSig = maxSig = earthquakes.get(0).sig;
  
  for (Earthquake eq : earthquakes) {
    minMagnitude = min(minMagnitude, eq.magnitude);
    maxMagnitude = max(maxMagnitude, eq.magnitude);
    minDepth = min(minDepth, eq.depth);
    maxDepth = max(maxDepth, eq.depth);
    minSig = min(minSig, eq.sig);
    maxSig = max(maxSig, eq.sig);
  }
  
  println("Data ranges:");
  println("  Magnitude: " + minMagnitude + " - " + maxMagnitude);
  println("  Depth: " + minDepth + " - " + maxDepth);
  println("  Significance: " + minSig + " - " + maxSig);
}

void updatePlayback() {
  frameCounter++;
  
  if (frameCounter >= playbackSpeed) {
    frameCounter = 0;
    
    if (currentIndex < earthquakes.size()) {
      // Activate current earthquake
      Earthquake eq = earthquakes.get(currentIndex);
      eq.isActive = true;
      
      // Send data to Pure Data
      sendEarthquakeToOSC(eq);
      
      currentIndex++;
      
      // If we finished all earthquakes, switch to interactive mode
      if (currentIndex >= earthquakes.size()) {
        currentState = State.INTERACTIVE;
        println("Playback complete. Interactive mode activated.");
      }
    }
  }
}

void drawAllEarthquakes() {
  // Draw all active earthquakes
  for (int i = 0; i < earthquakes.size(); i++) {
    Earthquake eq = earthquakes.get(i);
    
    if (eq.isActive) {
      // Highlight if selected
      boolean isSelected = (eq == selectedEarthquake);
      eq.display(isSelected);
    }
  }
}

void drawSimplifiedWorld() {
  // Draw simplified continents as filled shapes
  fill(20, 60, 20, 100); // Dark green semi-transparent
  noStroke();
  
  // North America (simplified)
  beginShape();
  addVertex(-170, 70); addVertex(-170, 15); addVertex(-80, 10);
  addVertex(-70, 25); addVertex(-60, 45); addVertex(-80, 70);
  addVertex(-130, 72); addVertex(-170, 70);
  endShape(CLOSE);
  
  // South America (simplified)
  beginShape();
  addVertex(-80, 10); addVertex(-35, -5); addVertex(-35, -55);
  addVertex(-70, -55); addVertex(-75, -20); addVertex(-80, 10);
  endShape(CLOSE);
  
  // Europe (simplified)
  beginShape();
  addVertex(-10, 35); addVertex(40, 35); addVertex(40, 70);
  addVertex(-10, 60); addVertex(-10, 35);
  endShape(CLOSE);
  
  // Africa (simplified)
  beginShape();
  addVertex(-20, 35); addVertex(50, 35); addVertex(40, -35);
  addVertex(20, -35); addVertex(-20, 10); addVertex(-20, 35);
  endShape(CLOSE);
  
  // Asia (simplified)
  beginShape();
  addVertex(40, 70); addVertex(180, 70); addVertex(145, 10);
  addVertex(95, 5); addVertex(60, 30); addVertex(40, 35); addVertex(40, 70);
  endShape(CLOSE);
  
  // Australia (simplified)
  beginShape();
  addVertex(110, -10); addVertex(155, -10); addVertex(155, -40);
  addVertex(110, -40); addVertex(110, -10);
  endShape(CLOSE);
  
  // Antarctica (simplified)
  fill(220, 240, 255, 80); // Ice blue
  beginShape();
  addVertex(-180, -60); addVertex(180, -60); addVertex(180, -90);
  addVertex(-180, -90); addVertex(-180, -60);
  endShape(CLOSE);
}

void addVertex(float lon, float lat) {
  float x = map(lon, -180, 180, 0, width);
  float y = map(lat, 90, -90, 0, height);
  vertex(x, y);
}

void drawGrid() {
  stroke(40, 80);
  strokeWeight(1);
  
  // Vertical lines (longitude)
  for (float lon = -180; lon <= 180; lon += 30) {
    float x = map(lon, -180, 180, 0, width);
    line(x, 0, x, height);
  }
  
  // Horizontal lines (latitude)
  for (float lat = -90; lat <= 90; lat += 30) {
    float y = map(lat, 90, -90, 0, height);
    line(0, y, width, y);
  }
  
  // Equator line
  stroke(60, 120);
  strokeWeight(2);
  float equatorY = map(0, 90, -90, 0, height);
  line(0, equatorY, width, equatorY);
  
  // Prime meridian line
  float meridianX = map(0, -180, 180, 0, width);
  line(meridianX, 0, meridianX, height);
}

void drawLoadingScreen() {
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(32);
  text("Loading data...", width/2, height/2);
}

void drawPlaybackInfo() {
  // Information panel
  fill(0, 200);
  noStroke();
  rect(10, 10, 350, 120);
  
  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  text("MODE: PLAYBACK", 20, 20);
  text("Earthquake: " + currentIndex + " / " + earthquakes.size(), 20, 40);
  text("Speed: " + playbackSpeed + " frames", 20, 60);
  text("SPACE: pause | I: interactive", 20, 80);
  text("M: toggle map | R: restart", 20, 100);
}

void drawInteractiveInfo() {
  // Information panel
  fill(0, 200);
  noStroke();
  rect(10, 10, 420, 140);
  
  fill(100, 255, 100);
  textAlign(LEFT, TOP);
  textSize(14);
  text("MODE: INTERACTIVE", 20, 20);
  text("Click: Re-play earthquake", 20, 40);
  text("Drag: Modify position and sound", 20, 60);
  text("W/S: Magnitude | A/D: Depth | T: Tsunami", 20, 80);
  text("R: Restart | +/-: Speed | M: Map", 20, 100);
  text("Map: " + (drawContinents ? "ON" : "OFF"), 20, 120);
  
  if (selectedEarthquake != null) {
    fill(0, 200);
    rect(10, 140, 400, 120);
    fill(255, 255, 100);
    text("SELECTED EARTHQUAKE:", 20, 150);
    text("Date: " + selectedEarthquake.dateTime, 20, 170);
    text("Magnitude: " + nf(selectedEarthquake.magnitude, 1, 2), 20, 190);
    text("Depth: " + nf(selectedEarthquake.depth, 1, 1) + " km", 20, 210);
    text("Tsunami: " + (selectedEarthquake.tsunami == 1 ? "YES" : "NO"), 20, 230);
  }
}

void handleMouseInteraction() {
  if (dragging && selectedEarthquake != null) {
    // Update position of dragged earthquake
    selectedEarthquake.latitude = map(mouseY, 0, height, 90, -90);
    selectedEarthquake.longitude = map(mouseX, 0, width, -180, 180);
    
    // Send update to Pure Data only every few frames (throttle)
    if (frameCount - lastSendFrame >= sendInterval) {
      sendEarthquakeToOSC(selectedEarthquake);
      lastSendFrame = frameCount;
    }
  }
}

void sendEarthquakeToOSC(Earthquake eq) {
  // Map magnitude to amplitude (0.0 - 1.0)
  float amplitude = map(eq.magnitude, minMagnitude, maxMagnitude, 0.2, 1.0);
  amplitude = constrain(amplitude, 0.0, 1.0);
  
  // Map depth to pitch (lower frequencies for greater depth)
  // Approximate range: 200 Hz (deep) to 1000 Hz (shallow)
  float pitch = map(eq.depth, minDepth, maxDepth, 1000, 200);
  pitch = constrain(pitch, 200, 1000);
  
  // Map longitude to panning (-1.0 left, 1.0 right)
  float pan = map(eq.longitude, -180, 180, -1.0, 1.0);
  pan = constrain(pan, -1.0, 1.0);
  
  // Significance (normalized)
  float significance = map(eq.sig, minSig, maxSig, 0.0, 1.0);
  significance = constrain(significance, 0.0, 1.0);
  
  // Duration based on magnitude (longer for bigger earthquakes)
  // Range: 500ms to 2000ms
  float duration = map(eq.magnitude, minMagnitude, maxMagnitude, 500, 2000);
  duration = constrain(duration, 500, 2000);
  
  // Create message in FUDI format (Pure Data's native format)
  // Format: "amplitude pitch pan tsunami significance magnitude depth duration trigger;"
  // trigger=1 tells PD to start the envelope
  String message = amplitude + " " + pitch + " " + pan + " " + 
                   eq.tsunami + " " + significance + " " + 
                   eq.magnitude + " " + eq.depth + " " + 
                   duration + " 1;\n";  // Added duration and trigger
  
  // Send via UDP
  try {
    byte[] data = message.getBytes();
    DatagramPacket packet = new DatagramPacket(data, data.length, pdAddress, 3000);
    udpSocket.send(packet);
    
    // Debug
    println("SENT -> Mag:" + nf(eq.magnitude,1,1) + 
            " Amp:" + nf(amplitude,1,2) + 
            " Pitch:" + nf(pitch,1,0) + 
            " Pan:" + nf(pan,1,2) + 
            " Dur:" + nf(duration,1,0) + "ms" +
            " Tsunami:" + eq.tsunami);
  } catch (Exception e) {
    println("Error sending UDP: " + e.getMessage());
  }
}

void mousePressed() {
  if (currentState == State.INTERACTIVE) {
    // Search if we clicked on an existing earthquake
    Earthquake clicked = null;
    
    for (int i = earthquakes.size() - 1; i >= 0; i--) {
      Earthquake eq = earthquakes.get(i);
      if (eq.isActive && eq.contains(mouseX, mouseY)) {
        clicked = eq;
        break;
      }
    }
    
    if (clicked != null) {
      // Re-play the clicked earthquake
      selectedEarthquake = clicked;
      dragging = true;
      sendEarthquakeToOSC(clicked);
    }
  }
}

void mouseReleased() {
  dragging = false;
}

void keyPressed() {
  if (key == ' ') {
    // Pause/resume
    if (currentState == State.PLAYING) {
      currentState = State.INTERACTIVE;
      println("PAUSED - Interactive mode");
    } else if (currentState == State.INTERACTIVE && currentIndex < earthquakes.size()) {
      currentState = State.PLAYING;
      println("RESUMING playback");
    }
  }
  
  if (key == 'i' || key == 'I') {
    // Jump to interactive mode
    if (currentState == State.PLAYING) {
      // Activate all remaining earthquakes
      for (int i = currentIndex; i < earthquakes.size(); i++) {
        earthquakes.get(i).isActive = true;
      }
      currentIndex = earthquakes.size();
      currentState = State.INTERACTIVE;
      println("Interactive mode activated manually");
    }
  }
  
  if (key == 'r' || key == 'R') {
    // Restart
    resetPlayback();
  }
  
  if (key == 'm' || key == 'M') {
    // Toggle world map
    drawContinents = !drawContinents;
    println("World map: " + (drawContinents ? "ON" : "OFF"));
  }
  
  if (key == 'g' || key == 'G') {
    // Toggle grid (could add a boolean for this)
    println("Grid toggle - implement if needed");
  }
  
  if (key == '+' || key == '=') {
    playbackSpeed = max(1, playbackSpeed - 5);
    println("Speed: " + playbackSpeed);
  }
  
  if (key == '-' || key == '_') {
    playbackSpeed += 5;
    println("Speed: " + playbackSpeed);
  }
  
  // Modify selected earthquake magnitude
  if (selectedEarthquake != null && currentState == State.INTERACTIVE) {
    if (key == 'w' || key == 'W') {
      selectedEarthquake.magnitude = min(9.0, selectedEarthquake.magnitude + 0.1);
      sendEarthquakeToOSC(selectedEarthquake);
    }
    if (key == 's' || key == 'S') {
      selectedEarthquake.magnitude = max(4.0, selectedEarthquake.magnitude - 0.1);
      sendEarthquakeToOSC(selectedEarthquake);
    }
    if (key == 'd' || key == 'D') {
      selectedEarthquake.depth = min(700, selectedEarthquake.depth + 10);
      sendEarthquakeToOSC(selectedEarthquake);
    }
    if (key == 'a' || key == 'A') {
      selectedEarthquake.depth = max(0, selectedEarthquake.depth - 10);
      sendEarthquakeToOSC(selectedEarthquake);
    }
    if (key == 't' || key == 'T') {
      selectedEarthquake.tsunami = 1 - selectedEarthquake.tsunami;
      sendEarthquakeToOSC(selectedEarthquake);
    }
  }
}

void resetPlayback() {
  currentIndex = 0;
  frameCounter = 0;
  selectedEarthquake = null;
  dragging = false;
  
  // Deactivate all earthquakes
  for (Earthquake eq : earthquakes) {
    eq.isActive = false;
  }
  
  currentState = State.PLAYING;
  println("Restarting playback...");
}

// Earthquake Class
class Earthquake {
  String dateTime;
  float magnitude;
  float depth;
  float latitude;
  float longitude;
  int sig;
  int tsunami;
  
  boolean isActive = false;
  boolean isUserCreated = false;
  
  float x, y;  // Posición en pantalla
  float diameter;
  color fillColor;
  color bgColor;
  
  Earthquake(String dt, float mag, float dep, float lat, float lon, int s, int tsu) {
    dateTime = dt;
    magnitude = mag;
    depth = dep;
    latitude = lat;
    longitude = lon;
    sig = s;
    tsunami = tsu;
    
    updateVisualProperties();
  }
  
  void updateVisualProperties() {
    // Map geographic coordinates to screen
    x = map(longitude, -180, 180, 0, width);
    y = map(latitude, 90, -90, 0, height);
    
    // Map magnitude to diameter
    diameter = map(magnitude, minMagnitude, maxMagnitude, 5, 80);
    diameter = constrain(diameter, 5, 80);
    
    // Circle color based on significance (sig)
    // Blue -> Orange -> Red
    float sigNorm = map(sig, minSig, maxSig, 0, 1);
    sigNorm = constrain(sigNorm, 0, 1);
    
    if (sigNorm < 0.5) {
      // Blue to Orange
      fillColor = lerpColor(color(50, 100, 255), color(255, 165, 0), sigNorm * 2);
    } else {
      // Orange to Red
      fillColor = lerpColor(color(255, 165, 0), color(255, 50, 50), (sigNorm - 0.5) * 2);
    }
    
    // Background color based on depth
    // Green (shallow) to Orange (deep)
    float depthNorm = map(depth, minDepth, maxDepth, 0, 1);
    depthNorm = constrain(depthNorm, 0, 1);
    bgColor = lerpColor(color(50, 255, 50, 100), color(255, 100, 0, 100), depthNorm);
    
    // If tsunami, use red background
    if (tsunami == 1) {
      bgColor = color(255, 0, 0, 150);
    }
  }
  
  void display(boolean isSelected) {
    updateVisualProperties();
    
    // Draw background/aura (depth or tsunami)
    noStroke();
    fill(bgColor);
    ellipse(x, y, diameter * 2, diameter * 2);
    
    // Draw main circle (significance)
    if (isSelected) {
      strokeWeight(3);
      stroke(255, 255, 0);
    } else {
      strokeWeight(1);
      stroke(255, 150);
    }
    
    fill(fillColor);
    ellipse(x, y, diameter, diameter);
    
    // If user created, mark with a white dot
    if (isUserCreated) {
      fill(255);
      noStroke();
      ellipse(x, y, 5, 5);
    }
  }
  
  boolean contains(float px, float py) {
    float d = dist(px, py, x, y);
    return d < diameter / 2;
  }
}
