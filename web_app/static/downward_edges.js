// from the Cola "downward pointing edges" example
// src: http://marvl.infotech.monash.edu/webcola/examples/downwardedges.html

// with some modifications

var width = 960,
    height = 1500;

var color = d3.scale.category20b();

var d3cola = cola.d3adaptor()
    .avoidOverlaps(true)
    // .linkDistance(500)
    .size([width, height]);

var svg = d3.select("div#main").append("svg")
    .attr("width", width)
    .attr("height", height);

d3.json("dynamic_data.json", function (error, graph) {
    if (error) throw error;
    
    var nodeCollisionRadius =  20;
    var nodeVisualRadius    =   8; //  10
    var nodeSymbolSize      = 100; // 140
    
    
    graph.nodes.forEach(function (v) { v.height = v.width = 2 * nodeCollisionRadius; });
    // graph.nodes.forEach(function (v) { v.height = v.width = 20; });
    
    d3cola
        .nodes(graph.nodes)
        .links(graph.links)
        .flowLayout("y", 30)
        .symmetricDiffLinkLengths(6)
        .start(10,20,20);
    
    // define arrow markers for graph links
    svg.append('svg:defs').append('svg:marker')
        .attr('id', 'end-arrow')
        .attr('viewBox', '0 -5 10 10')
        .attr('refX', 6)
        .attr('markerWidth', 3)
        .attr('markerHeight', 3)
        .attr('orient', 'auto')
      .append('svg:path')
        .attr('d', 'M0,-5L10,0L0,5')
        .attr('fill', '#000');
    
    var path =
        svg.selectAll(".link")
        .data(graph.links)
        .enter()
          .append('svg:path')
          .attr('class', 'link');
    
    
    // code for varing symbols from here (has been edited a bit to integrate with the other stuff)
    // src: bl.ocks.org/d3noob/11137963
    
    // Declare the nodes…
    var node = svg.selectAll("g.node")
      .data(graph.nodes, function(d) { return d.number; });
    
    // Enter the nodes.
    var nodeEnter = node.enter().append("g")
      .attr("class", "node")
      .attr("transform", function(d) { 
          return "translate(" + d.y + "," + d.x + ")";
      })
      .call(d3cola.drag);
    
    nodeEnter.append("path")
             .attr("class", function(d) { 
                return d.class;
             })
             // .style("stroke", "black")
             // .style("fill", function(d){
             //    return color(d.elective_type);
             // })
             .attr("d", d3.svg.symbol()
                          .size(nodeSymbolSize)
                          .type(function(d) { if
                             (d.class == 'required'     ) { return "circle"; } else if
                             (d.class == 'elective'     ) { return "square";} else if
                             (d.class == 'not-required' ) { return "triangle-up";} else if
                             (d.class == 'split-link'   ) { return "cross";}
                           }));
    
    
    color.domain([0,1,2,3,4,5,6,7,8,9,10]);
    nodeEnter.selectAll('.elective')
             .style("fill", function(d){
                console.log(d.elective_type);
                return color(d.elective_type);
             });
    
    console.log(color.range());
    
    
    // TODO: send and bind additional data showing the different categories that electives can be placed into. Want to show color swatches next to text descriptions of the different categories. ie: pick two of these color nodes.
    d3.select('div#swatch-container').selectAll('div.swatch')
      ;
    
    // nodeEnter.append("text")
    //       // .attr("x", function(d) { 
    //       //     return d.children || d._children ? 
    //       //     (d.value + 4) * -1 : d.value + 4
    //       // })
    //       // .attr("dy", ".35em")
    //       // .attr("text-anchor", function(d) { 
    //       //     return d.children || d._children ? "end" : "start"; })
    //       .text(function(d) { return d.name; })
    //       .style("fill-opacity", 1);
    
    
    
    
    
    node.append("title")
        .text(function (d) { return d.name; });
    
    d3cola.on("tick", function () {
        path.each(function (d) {
            if (isIE()) this.parentNode.insertBefore(this, this);
        });
        // draw directed edges with proper padding from node centers
        path.attr('d', function (d) {
            // console.log(d);
            // if you're getting NaN from this function,
            // it's probably because dist == 0
            
            var deltaX = d.target.x - d.source.x,
                deltaY = d.target.y - d.source.y,
                dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY),
                normX = deltaX / dist,
                normY = deltaY / dist,
                sourcePadding = nodeVisualRadius,
                targetPadding = nodeVisualRadius + 2,
                sourceX = d.source.x + (sourcePadding * normX),
                sourceY = d.source.y + (sourcePadding * normY),
                targetX = d.target.x - (targetPadding * normX),
                targetY = d.target.y - (targetPadding * normY);
            // console.log(dist);
            return 'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY;
        });
        
        
        node.attr("transform", function(d) { 
          return "translate(" + d.x + "," + d.y + ")";
        });
    });
    // turn on overlap avoidance after first convergence
    //cola.on("end", function () {
    //    if (!cola.avoidOverlaps()) {
    //        graph.nodes.forEach(function (v) {
    //            v.width = v.height = 10;
    //        });
    //        cola.avoidOverlaps(true);
    //        cola.start();
    //    }
    //});
    
    
    
    
    var paths_to_highlight;
    node.on('mouseover', function(hovered) {
        // console.log("callback");
        // console.log(hovered);
        course_info_display(hovered);
        
        set = new Set(hovered.chain_deps);
        set.add(hovered.number);
        
        // console.log(set);
        
        
        paths_to_highlight = 
          path.filter(function (d) {
              return set.has(d.source.number) && 
                     set.has(d.target.number);
          })
        
        paths_to_highlight
        .attr('style', 'stroke: red;');
        // TODO: apply a style instead (better coding style, but more complicated)
        
        
        
        nodes_to_highlight = 
          node.filter(function (d) {
              return set.has(d.number);
          })
        
        nodes_to_highlight
        .attr('style', 'stroke: red;');
    })
    .on("mouseout", function(d) {
        paths_to_highlight.attr('style', '');
        nodes_to_highlight.attr('style', '');
    })
});

function isIE() { return ((navigator.appName == 'Microsoft Internet Explorer') || ((navigator.appName == 'Netscape') && (new RegExp("Trident/.*rv:([0-9]{1,}[\.0-9]{0,})").exec(navigator.userAgent) != null))); }

