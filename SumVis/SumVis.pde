// SumVis by Ticha Sethapakdi
// Some code adapted from Processing examples and 
// Daniel Shiffman's The Nature of Code 

import toxi.geom.*;
import toxi.physics2d.*;
import toxi.physics2d.behaviors.*;
import controlP5.*; 

/******* FOR THE MAIN VISUALIZATION *******/
ControlP5 cp5;

// Reference to physics world
VerletPhysics2D physics;

color bgcol = #0e2f44; 

// the main cluster
Cluster c; 

// the cluster for an expanded glyph
Cluster e; 

// name of the input file for VOG's output
private String dataset;

PFont bitfont;

// Clique customization
int cliqueRoundness = 0;
float fc_hue = 352; 
float st_hue = 39;
float ch_hue = 179;
float bc_hue = 276; 
float node_hue = 87.27;

// UI handling
controlP5.Slider[] customization = new controlP5.Slider[2];
boolean glyphOptionsVisible = false; 

controlP5.Button expandGlyphButton;
controlP5.Button returnButton; 

// Distinct structures found by VOG 
// (used by the displayed list in the bottom-right hand corner)
// Organized as: {Full Cliques, Stars, Chains, Bipartite Cores, Near-Bipartite Cores}
int[] structuresFound = new int[5]; 

// variable that determine whether we are looking at an expanded glyph
boolean isExpanded = false; 

// index that keeps track of where we are in the structure file
int structureFilePos = 0; 
int newStructureFilePos = 0; 

int datasetlen; 

/******* FOR THE SPY PLOT *******/
// the name of the input file used to create the spy plot
private String spyplotdata; 

// The spy plot, represented as a 2D boolean array.
// if SpyPlot[u][v] is true, that means there is an edge from u->v
PlotPoint[][] SpyPlot; 

int minYAxis = Integer.MAX_VALUE; // smallest number on the Y-axis
int maxYAxis = Integer.MIN_VALUE; // largest number on the Y-axis 
int minXAxis = Integer.MAX_VALUE; // smallest number on the X-axis
int maxXAxis = Integer.MIN_VALUE; // largest number on the X-axis 

int numrows; 
int numcols; 
int plotsize; 

int minNodeID;
int maxNodeID;

boolean foundselected;

void setup() {
  background(bgcol); 
  colorMode(HSB, 360, 100, 100);
  size(1200,700);  
  textSize(15);
  cp5 = new ControlP5(this);
  pixelDensity(displayDensity());
  
  //bitfont = createFont("Nintendo-DS-BIOS",20,true);
  bitfont = loadFont("Nintendo-DS-BIOS-48.vlw"); 
  textFont(bitfont, 20); 
  
  prepareVisualization(); 
  prepareSpyPlot();
  
  rectMode(CENTER); 
  
  smooth(); 
  
}

void draw() {
  makeVisualization(); 
  makeSpyPlot(); 
  drawUI();
}

void drawUI() {
  textAlign(LEFT);
  textSize(18);  
  fill(#ffffff);
  
   // scrolling rectangle   
  float rectPosX = map(newStructureFilePos, 0, datasetlen-5, 630, 730);
  rectMode(CENTER);
  
  text("Showing structures " + newStructureFilePos + "-" + int(newStructureFilePos+4), 628, 600);
  
  if(newStructureFilePos == 0) {
    fill(#ffffff); 
    text("^scroll for more", rectPosX-2, 655); 
    fill(#ffffff);
  }
  else
    fill(#3399ff);
  
  rect(rectPosX, 624, 4,25);
}

void prepareVisualization() {
  // Initialize the physics
  physics=new VerletPhysics2D();
  physics.setWorldBounds(new Rect(10,10,width-20,height-20));
  
  // create graph
  Vec2D center = new Vec2D(width*0.75,height/2);
  
  String path = dataPath("");
  File[] files = listFiles(path);
  for(int i = 0; i < files.length; i++) { 
    String filename = files[i].getName();
    
    // use the first model file that is found in the data directory as input
    if(filename.endsWith(".model")) {
      dataset = filename; 
      break; 
    }
  }
  
  c = new Cluster(dataset, 250, center, true);
  
  datasetlen = loadStrings(dataset).length; 
  
  translate(600,0);
  createUI();
}

void makeVisualization() {
  background(bgcol); 
  
  textSize(20);
  fill(360); 
  text("DATASET: " + dataset, 630, 30);
  
  physics.update();
  
  c.showConnections();  
  c.display();
  String foundStructures; 
  int numDistinctStructures = 0; 
  
  if(newStructureFilePos != structureFilePos) {
    for(int i = 0; i < plotsize; i++) {
      for(int j = 0; j < plotsize; j++) {
        SpyPlot[i][j].isFirst = false;
        SpyPlot[i][j].isSecond = false; 
      }
    }
    foundselected = false;
    structureFilePos = newStructureFilePos; 
    returnToGraph();
  }
  
  // Text box showing structures found
  if(!isExpanded) {
    foundStructures = "STRUCTURES DISPLAYED:\n"; 
    
    for(int i = 0; i < structuresFound.length; i++) {
      int structurecount = structuresFound[i];
      
      if(structurecount > 0) {
        foundStructures += structurecount; 
        numDistinctStructures++; 
        
        switch(i) {
          case 0:
            foundStructures += "  Full  Clique"; 
            break;
           case 1:
            foundStructures += "  Star"; 
            break;
           case 2:
            foundStructures += "  Chain"; 
            break;
           case 3:
            foundStructures += "  Bipartite  Core"; 
            break;
           case 4:
            foundStructures += "  Near-Bipartite  Core"; 
            break;
        }
        
        if(structurecount > 1) {
          foundStructures += "s"; 
        }
        
        foundStructures += "\n"; 
      }
    }
  }
  else {
    foundStructures = "Showing top 5 nodes in the expanded structure."; 
    numDistinctStructures = 2; 
  }
  
  fill(#071722, 200); 
  noStroke(); 
  rectMode(CORNERS); 
  // corners of rectangles
  float upperleftcorner_x = width*0.7; 
  float upperleftcorner_y =  height-63-25*numDistinctStructures; 
  float bottomrightcorner_x = width-30; 
  float bottomrightcorner_y = height-30; 
  rect(upperleftcorner_x, upperleftcorner_y, bottomrightcorner_x, bottomrightcorner_y, 3); 
  
  fill(360); 
  text(foundStructures, 
        upperleftcorner_x + 10, upperleftcorner_y + 10,
        bottomrightcorner_x-10, bottomrightcorner_y-10);
}

void prepareSpyPlot() {
  
  String path = dataPath("");
  File[] files = listFiles(path);
  for(int i = 0; i < files.length; i++) { 
    String filename = files[i].getName();
    
    // use the first model file that is found in the data directory as input
    if(filename.endsWith(".out")) {
      spyplotdata = filename; 
      break; 
    }
  }
  
  // put the full data into an array
  String[] inputGraph = loadStrings(spyplotdata); 
  
  // iterate through data once to establish the range of node numbers
  for(int i = 0; i < inputGraph.length; i++) {
    int rowVertex = int(split(inputGraph[i], ',')[0]); 
    int colVertex = int(split(inputGraph[i], ',')[1]);
    
    if(rowVertex > maxYAxis) maxYAxis = rowVertex;
    if(rowVertex < minYAxis) minYAxis = rowVertex; 
    if(colVertex > maxXAxis) maxXAxis = colVertex;
    if(colVertex < minXAxis) minXAxis = colVertex; 
  }
  
  numrows = maxYAxis-minYAxis+1;
  numcols = maxXAxis-minXAxis+1; 
  
  plotsize = max(maxXAxis, maxYAxis)-min(minXAxis,minYAxis)+1; 
  minNodeID = min(minXAxis,minYAxis);  
  maxNodeID = max(maxXAxis,maxYAxis); 
  
  SpyPlot = new PlotPoint[plotsize][plotsize]; 
  
  // initialize SpyPlot
  for(int i = 0; i < plotsize; i++) {
    for(int j = 0; j < plotsize; j++) {
      SpyPlot[i][j] = new PlotPoint(0, 0);
    }
  }
  
  // iterate through data again to populate the spy plot
  for(int i = 0; i < inputGraph.length; i++) {
    int rowVertex = int(split(inputGraph[i], ',')[0]); 
    int colVertex = int(split(inputGraph[i], ',')[1]);
    
    int colVal = colVertex-minNodeID; 
    int rowVal = rowVertex-minNodeID;
    
    // add edge in both directions
    SpyPlot[rowVal][colVal].yPos = rowVal;
    SpyPlot[rowVal][colVal].xPos = colVal; 
    SpyPlot[rowVal][colVal].hasEdge = true;
    
    SpyPlot[colVal][rowVal].yPos = colVal;
    SpyPlot[colVal][rowVal].xPos = rowVal; 
    SpyPlot[colVal][rowVal].hasEdge = true; 
  }
  
}

// draws the SpyPlot
void makeSpyPlot() {
  fill(#f5f5f5);
  rect(0,0,width/2, height);
  
  pushMatrix();
  translate((width/2-plotWidth)/2,(height-plotWidth)/2); 
  
  int step = ceil((maxNodeID-minNodeID+1)/9);
  
  // now draw the axis labels
  for(int i = minNodeID; i <= maxNodeID; i+=step) {
    float axisPos = map(i, minNodeID, maxNodeID, 0, plotWidth); 
    
    textAlign(CENTER);
    // x axis labels
    fill(0);
    ellipse(axisPos, -10, plotWidth/plotsize,plotWidth/plotsize);
    
    text(i, axisPos, -20); 
    
    textAlign(RIGHT);
    // y axis labels
    fill(0);
    ellipse(-10, axisPos, plotWidth/plotsize,plotWidth/plotsize);
    
    text(i, -20, axisPos + 5); 
   
  }
  
  textAlign(LEFT);
  
  // display the SpyPlot
  for(int i = 0; i < plotsize; i++) {
    for(int j = 0; j < plotsize; j++) {
      SpyPlot[i][j].display(); 
    }
  }
  
  popMatrix(); 
}

void createUI() {
  // UI BUTTONS!!
  cp5.addButton("saveScreen")
     .setLabel("Save Screen")
     .setPosition(width*0.55,50)
     .setSize(100,30)
     .setColorBackground(#061b28)
     .setColorForeground(#ff8c19)
     ;
  /* 
  expandGlyphButton = cp5.addButton("expandGlyph")
     .setLabel("Tell Me More")
     .setPosition(930,50)
     .setSize(110,30)
     .setColorBackground(#061b28)
     .setColorForeground(#ff8c19)
     .hide(); 
     ;*/
     
  returnButton = cp5.addButton("returnToGraph")
     .setLabel("Go Back")
     .setPosition(970,50)
     .setSize(110,30)
     .setColorBackground(#061b28)
     .setColorForeground(#ff8c19)
     .hide(); 
     ;
  
  // Position in file slider
  if(datasetlen > 5) {
    cp5.addSlider("newStructureFilePos")
       .setPosition(630,620)
       .setRange(0, datasetlen-5)
       .setSize(100,10) 
       .setColorBackground(#ffffff) 
       .setColorForeground(#3399ff)
       .setColorValue(#ffffff)
       .setColorActive(#3399ff)
       .setLabel(" ")
       ;
  }
  
  
  // UI SLIDERS!!
  customization[0] = cp5.addSlider("cliqueRoundness")
     .setPosition(630,100)
     .setRange(0,7)
     .setLabel("Clique Roundness")
     .setVisible(false)
     ;
     
  customization[1] = cp5.addSlider("fc_hue")
     .setPosition(630,130)
     .setRange(0,360)
     .setLabel("Clique Hue")
     .setVisible(false)
     ;
     
}

void mouseReleased() {
  ArrayList<Glyph> glyphs = c.getGlyphs(); 
  foundselected = false; 
  
  for (Glyph g: glyphs) {
    if(g.clicked) {
      g.setSelected(true); 
      /*
      if(!isExpanded)
        expandGlyphButton.show();
      */
      foundselected = true; 
      
    }
    else {
      g.setSelected(false); 
    }
    
    g.setClicked(false); 
  }
  
  /*if(!foundselected) {
    expandGlyphButton.hide();
    
  }*/
}

void mousePressed() {
  ArrayList<Glyph> glyphs = c.getGlyphs(); 
  // Check to see if the mouse was clicked on the box
  for (Glyph g: glyphs) {
    if(g.contains(mouseX,mouseY)) {
      g.setClicked(true); 
      
      
      
      break; 
    }
  }
}

// UI STUFF
public void expandGlyph(int theValue) {
  ArrayList<Glyph> glyphs = c.getGlyphs(); 
  for (Glyph g: glyphs) {
    if(g.selected) {
      String glyphEncoding = g.glyphclass;
      
      // the new cluster center
      Vec2D center = new Vec2D(width*.75,height/2);
      
      // Note: it's bad practice to reassign references to allocated objects all the time,
      // but I can't think of a cleaner way around this--
      // hopefully the garbage collector is active enough to take care of things
      c = new Cluster(glyphEncoding, 200, center, false);
      
      break; 
    }
  }
  
  isExpanded = true; 
  returnButton.show();
  
}

public void returnToGraph() {
  // the new cluster center
  Vec2D center = new Vec2D(width*.75,height/2);
  
  c = new Cluster(dataset, 250, center, true);
  
  isExpanded = false; 
  returnButton.hide();
}

public void next5(int theValue) {
  
  // ADJUST THIS TO LENGTH OF THE FILE
  if(structureFilePos < datasetlen-5) {
    structureFilePos++; 
    
    // the new cluster center
    Vec2D center = new Vec2D(width/2,height/2);
    
    c = new Cluster(dataset, 250, center, true);
    
    isExpanded = false; 
    returnButton.hide();
    
  }
}

public void previous5(int theValue) {
  if(structureFilePos > 0) {
    structureFilePos--; 
    
    // the new cluster center
    Vec2D center = new Vec2D(width/2,height/2);
    
    c = new Cluster(dataset, 250, center, true);
    
    isExpanded = false; 
    returnButton.hide();
    
  }
}

public void glyphOptions(int theValue) {
  if(glyphOptionsVisible) {
    for (int i = 0; i < customization.length; i++) {
      customization[i].hide(); 
    }
    glyphOptionsVisible = false; 
  }
  
  else {
    for (int i = 0; i < customization.length; i++) {
      customization[i].show(); 
    }
    glyphOptionsVisible = true; 
  }
  
}

public void saveScreen(int theValue) {
  saveFrame(); 
}

//taken from http://processing.org/learning/topics/directorylist.html
File[] listFiles(String dir) {
 File file = new File(dir);
 if (file.isDirectory()) {
   File[] files = file.listFiles();
   return files;
 } else {
   // If it's not a directory
   return null;
 }
}