// 2012-03-19 Galo Navarro <anglorvaroa@gmail.com> 
//
// Displays commits as growing circles in a grid or circle with
// a center per committer. Code not nice. I just wanted to get things
// rendered.
//
// Uses a mercurial log output like:
//   hg log --template '{date}\t{author}\t{node}\n'
// I used source data from work so didn't commit

// screen setup
int width = 1200;
int height = 900;
boolean displayNames = true;
// time increment
int timeDelta = 60*60*10;
// start time
long currTime = 0;
// data input
String sep = "\t";
// date format, for status bar
SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
// current commit index
int lastRenderedCommitIdx=0;
// author pattern
Pattern pattern = Pattern.compile("\\w+@");

// input, loaded
String[] lines;

// data structures
List<Commit> commits = new ArrayList<Commit>();
HashMap<String, Author> authors = new HashMap<String, Author>();

// load source data 
void setup() {
  size(width, height);
  colorMode(HSB, 360, 100, 100);
  background(0);
  lines = loadStrings("mercurial.history.all");
  parseLines();
  Collections.reverse(commits);
  currTime = commits.get(0).time;  
}

// render the current status
void renderStatus() {
  fill(0, 100, 100);
  textAlign(LEFT);
  text(lastRenderedCommitIdx + "/" + commits.size() + " commits from " + authors.size() + " authors - " + df.format(new Date(currTime * 1000l)), 10, 25);   
}

// draw commits
void draw() { 
  smooth();
  noStroke();
  fill(0, 0, 0);
  rect(0, 0, width, height);  
  int size = commits.size();
  if (lastRenderedCommitIdx >= size) {
    System.exit(0);
  }
  
  Commit c;
  do {
    c = commits.get(lastRenderedCommitIdx++);
    authors.get(c.authorTag).addCommit(c);
  } while (c.time < currTime && lastRenderedCommitIdx < size);
  
  textSize(10);
  renderStatus();
  
  for (Author a : authors.values()) {
    a.draw();
  }
  
  currTime+=timeDelta;
}

// parse a Commit
Commit parse(String line) {  
  StringTokenizer tknzr = new StringTokenizer(line, sep);
  if (tknzr.countTokens() == 3) {
    String timestamp = tknzr.nextToken();
    String name = tknzr.nextToken();
    String rev = tknzr.nextToken();
    String files = ""; //tknzr.nextToken();
    timestamp = timestamp.substring(0, timestamp.indexOf("."));    
    long time = Long.parseLong(timestamp);
    Matcher matcher = pattern.matcher(name);
    if (matcher.find()) {
      name = matcher.group();
      name = name.substring(0, name.length()-1);
      return new Commit(time, name.toLowerCase(), rev, files);
    } else {
      return null;
    }
  } else {
    return null;
  }
}

// parse the lines and assign a place in the circumference
void parseLines() {
  int i = 0;
  for(String line : lines) {
    Commit c = parse(line);
    if (c != null) {
      Author author = authors.get(c.authorTag);
      if (author == null) {
        authors.put(c.authorTag, author = new Author(c.authorTag));
      }
      commits.add(c);
    }
  }
  
  layoutAsCircle();
  //layoutAsGrid();
  
}

// set authors in a grid layout
void layoutAsGrid() {
  int rows = ceil((float)Math.sqrt(authors.size()));
  int cols = ceil((float)Math.sqrt(authors.size()));
  int currRow = 0;
  int currCol = 0;
  for (Author a : authors.values()) {    
    a.place(new PVector(100 + (currCol * (width - 100) / cols), 100 + (currRow * (height - 100) / rows)));
    currCol = (currCol + 1) % cols;
    if (currCol == 0) {
      currRow = (currRow + 1) % rows;
    }
  }    
}

// set authors in a circle layout
void layoutAsCircle() {
  PVector center = new PVector(width / 2, (height - 10) / 2);
  int radius = (height - 100) / 2;
  float anglePerSector = 360 / authors.size();
  float angle = 0;
  for (Author a : authors.values()) {
    angle = (angle + anglePerSector);
    float x = center.x + radius * cos(angle);
    float y = center.y + radius * sin(angle);
    a.place(new PVector(x, y));
  }  
}

class Author {
  
  String name;
  List<Commit> commits;
  PVector p;
  
  Author (String name) {
    this.name = name;
    this.commits = new ArrayList<Commit>();
  }
  
  void place(PVector p) {
    this.p = p;
  }
  
  void addCommit(Commit c) {
    this.commits.add(c);
  }
  
  void draw() {
    float dotSize = 0.1;
    int size = this.commits.size();
    noStroke();
    fill(0, 0, 100);
    ellipse(this.p.x, this.p.y, size * dotSize, size * dotSize);
    if (displayNames) {
      stroke(255, 50, 100);
      fill(255, 50, 100);
      text (this.name + " (" + size + ")", this.p.x, this.p.y);
    }
  }
}

class Commit {
  
  String authorTag;
  String files;
  String rev;
  long time;
  PVector p;
  
  Commit (long time, String authorTag, String rev, String files) {
    this.time = time;
    this.authorTag = authorTag;
    this.files = files;
    this.rev = rev;
  }
  
  public String toString() {
    StringBuilder sb = new StringBuilder(this.authorTag);
    sb.append(", ").append(time);
    return sb.toString();
  }

}
