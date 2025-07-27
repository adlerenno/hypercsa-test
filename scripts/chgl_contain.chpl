use CHGL;
use IO;
use List;
use Set;

config const inputFile = "hypergraph.hg";
config const queryFile = "queries.hg";

proc parseLineToSet(line: string): set(int) {
  var s: set(int);
  for token in line.split(",") {
    s.add(token.strip().int);
  }
  return s;
}

proc main() {
  var edges: list(set(int));
  var maxNodeId = 0;

  // Step 1: Load hypergraph
  {
    var reader = open(inputFile, ioMode.r).reader();
    for line in reader.lines() {
      const edge = parseLineToSet(line);
      for node in edge do
        if node > maxNodeId then maxNodeId = node;
      edges.append(edge);
    }
    reader.close();
  }

  const numVertices = maxNodeId + 1;
  const numEdges = edges.size;

  // Step 2: Build CHGL HyperGraph
  var hg = new HyperGraph(numVertices, numEdges);
  for edge in edges do
    hg.addEdge(edge);

  // Step 3: Read queries and check for existence using CHGL only
  var reader = open(queryFile, ioMode.r).reader();
  for line in reader.lines() {
    const querySet = parseLineToSet(line);

    var found = false;
    for e in 0..<hg.numEdges {
      const edgeNodes = hg.getEdgeVertices(e);

      var edgeSet: set(int);
      for node in edgeNodes do edgeSet.add(node);

      if edgeSet == querySet {
        found = true;
        break;
      }
    }

    if found then writeln("exists");
    else writeln("not exists");
  }
  reader.close();
}
