// Takes the output of a tcpdump -ei wlan0 command and produces a
// visualization of beacon probes. On linux run iwconfig wlan0 mode
// monitor, then the tcpdump.
//
// Change the source variable below to the path of the file containing
// the dump.

import java.util.Iterator;

void LOG(String s) {
  System.out.println(s);
}

class Graph {
  HashMap<String, Node> nodes = new HashMap<String, Node>();
  void add(Node n) { if (nodes.put(n.tag, n) == null) LOG("New node " + n.tag); }
  void arrange() {
    int cX = WIDTH / 2, cY = HEIGHT / 2;
    // inc. radians = degrees per step * radians per degree
    float deltaRadians = (360/nodes.size()) * (float)(2 * Math.PI / 360);
    float startRadians = 0;
    float radius = cY * 0.8;
    for (String tag : nodes.keySet()) {
      Node n = nodes.get(tag);
      startRadians += deltaRadians;
      n.p = new PVector(cX + radius*sin(startRadians), 
                        cY + radius*cos(startRadians));
      n.pTag = new PVector(cX + (radius+10)*sin(startRadians),
                           cY + (radius+10)*cos(startRadians));
    }
  }
  void draw() { for (String tag : nodes.keySet()) { nodes.get(tag).draw(); } }
}

class Node {
  PVector p;
  PVector pTag;
  String tag;
  ArrayList<Message> msgs = new ArrayList<Message>();
  int grace = 0;
  Node(String tag) { 
    this(tag, new PVector(0, 0));
  }
  Node(String tag, PVector p) { 
    this.tag = tag;
    this.p = new PVector(p.x, p.y);
  }
  void draw() { 
    if (msgs.isEmpty() && grace == 0) { return; }
    if (grace > 0) grace--;
    fill(200, 200, 200);
    text(tag, pTag.x, pTag.y);
    fill(255, 200, 255);
    ellipse(p.x, p.y, 2, 2); 
    for (Iterator<Message> it = msgs.iterator(); it.hasNext();) {
      Message msg = it.next(); 
      if (msg.isExpired()) { it.remove(); grace = 100; }
      else { msg.draw(); msg.tic(); }
    }
  }
  void probe() { msgs.add(new Probe(this.p)); }
}

abstract class Message {
  PVector src;
  String msg;
  Message(PVector origin) { this.src = new PVector(origin.x, origin.y); }
  abstract void tic();
  abstract boolean isExpired();
  abstract void draw();
}

class Probe extends Message {
  int rad = 2;
  Probe (PVector origin) { super(origin); }
  void tic() { rad += 5; }
  boolean isExpired() { return rad >= 100; }
  void draw() { fill(100, 200, 100, 10); ellipse(src.x, src.y, rad, rad); }
}

String extractSSIDs(String s) {
  String[][] matches;
  if ((matches = matchAll(s, BEACON_SSID_REGEX)) != null) {
    return matches[0][1];
  } 
  return null;
}

void process(String s) {
  String[][] matches;
  if ((matches = matchAll(s, BEACON_SSID_REGEX)) != null) {
    String ssid = matches[0][1];
    graph.nodes.get(ssid).probe();
  }
}

// -------------------------------------------------------------
// -------------------------------------------------------------
// -------------------------------------------------------------

int WIDTH=1024;
int HEIGHT=700;

static final String PREQ_SSID_REGEX = "Probe Request \\((.*)\\)";
static final String PRES_SSID_REGEX = "Probe Response \\((.*)\\)";
static final String BEACON_SSID_REGEX = "Beacon \\((.*)\\)";

Graph graph = new Graph();
String[] lines;

int step = 0;
String source = "<dump>";

void setup() {
  size(WIDTH, HEIGHT);
  background(0);
  textFont(createFont("Arial", 12));
  lines = loadStrings(source);
  for (String s : lines) { 
    String ssid = extractSSIDs(s); 
    if (ssid != null) graph.add(new Node(ssid)); 
  }
  graph.arrange();
}

void draw() {
  if (step > lines.length) exit();
  noStroke();
  fill(0, 0, 0, 50);
  rect(0, 0, width, height);
  graph.draw();
  textSize(10);
  frameRate(100);
  process(lines[step++]);
}

