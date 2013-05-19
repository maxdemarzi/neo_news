function addNeo(graph, data) {
    function addNode(id, label) {
        if (!id || typeof id == "undefined") return null;
        var node = graph.getNode(id);
        if (!node) node = graph.addNode(id, label);
        return node;
    }

    for (n in data.edges) {
        if (data.edges[n].source) {
            addNode(data.edges[n].source, data.edges[n].source_data );
        }
        if (data.edges[n].target) {
            addNode(data.edges[n].target, data.edges[n].target_data);
        }
    }

    for (n in data.edges) {
        var edge=data.edges[n];
        var found=false;
        graph.forEachLinkedNode(edge.source, function (node, link) {
            if (node.id==edge.target) found=true;
        });
        if (!found && edge.source && edge.target) graph.addLink(edge.source, edge.target);
    }
}

function loadData(graph,id) {
    $.ajax(id ? "/edges/" + id : "/edges", {
        type:"GET",
        dataType:"json",
        success:function (res) {
            addNeo(graph, {edges:res});
        }
    })
}

function loadUrl(url) {
    $.ajax("/external/" + encodeURIComponent(url), {
        type:"GET",
        dataType:"json",
        success:function (res) {
            $('#explanation').html(res.lede);
        }
    })
}



function onLoad() {
  // Step 1. Create a graph:
  var graph = Viva.Graph.graph();	

  var layout = Viva.Graph.Layout.forceDirected(graph, {
      springLength:100,
      springCoeff:0.0001,
      dragCoeff:0.02,
      gravity:-1
  });	

  // Step 3. Customize node appearance.
  var graphics = Viva.Graph.View.svgGraphics();
  
   // we use this method to highlight all realted links
   // when user hovers mouse over a node:
   highlightRelatedNodes = function(nodeId, isOn) {
      // just enumerate all realted nodes and update link color:
      graph.forEachLinkedNode(nodeId, function(node, link){
          if (link && link.ui) {
              // link.ui is a special property of each link
              // points to the link presentation object.
              link.ui.attr('stroke', isOn ? 'white' : 'gray');
          }
      });
   };
  // This function let us override default node appearance and create
  // something better than blue dots:

  graphics.node(function(node) {
    // node.data holds custom object passed to graph.addNode():
    var ui = Viva.Graph.svg('text').attr('y', '-4px').text(node.data);

	$(ui).hover(function() { // mouse over
	                    highlightRelatedNodes(node.id, true);
	                }, function() { // mouse out
	                    highlightRelatedNodes(node.id, false);
	                });
	$(ui).click(function() { 
				        console.log("click", node);
			        	if (!node || !node.position) return;
                      	loadUrl(node.id);
			        	renderer.rerender();
			        	loadData(graph,node.id);
			}
	);

      return ui; 
  });
	
  var renderer = Viva.Graph.View.renderer(graph,
      {
          layout:layout,
          graphics:graphics,
          container:document.getElementById('graph'),
          renderLinks:true
      });	

	
  renderer.run();	

  var neoid = window.location.search.substring(1).split("=")[1];
  if ( neoid == "") {
   neoid = document.getElementById("neoid").value;
  };
  if ( neoid == "") {
   neoid = 1;
  };

  loadData(graph,neoid);
  
  }