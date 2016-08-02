// console.log("hello world")




// dragstart
// drag
// dragend



// http://stackoverflow.com/questions/19911514/how-can-i-click-to-add-or-drag-in-d3

function click(){
  // Ignore the click event if it was suppressed
  if (d3.event.defaultPrevented) return;

  // Extract the click location\    
  var point = d3.mouse(this)
  , p = {x: point[0], y: point[1] };

  // Append a new point
  svg.append("circle")
      .attr("transform", "translate(" + p.x + "," + p.y + ")")
      .attr("r", "5")
      .attr("class", "dot")
      .style("cursor", "pointer")
      .call(drag);
}

function dragmove(d) {
  var x = d3.event.x;
  var y = d3.event.y;
  d3.select(this).attr("transform", "translate(" + x + "," + y + ")");
}


// // overall size of the SVG work-area
var canvas = {width: 700, height: 500};

// Create the SVG
// var svg = d3.select("body").append("svg")
//   .attr("width",  canvas.width)
//   .attr("height", canvas.height)
//   .on("click", click);



// NOTE: SVG z-ordering is based on the order of tags in the document

// NOTE: getting some unexpected behaviors on drag again, for both circle and text. Need to really figure this out.


// Size the SVG element, and set the click handler.
// (click handler spawns new circles wherever you click)
var svg = d3.select("svg")
  .attr("width",  canvas.width)
  .attr("height", canvas.height)
  .on("click", click);

// Define drag beavior
var drag = d3.drag()
    .on("drag", dragmove);









 // You need to run the JavaScript after the element is ready/rendered. Whether that means inside of window.onload = function () { }; or just sometime literally after the input's HTML. Otherwise, the document.getElementById() won't be able to find the element. – Ian Jun 4 '13 at 21:07 
	// src: http://stackoverflow.com/questions/16927447/very-simple-javascript-doesnt-work-at-all





// https://www.dashingd3js.com/svg-basic-shapes-and-d3js


var jsonCircles = [
  { "x_axis": 30, "y_axis": 30, "radius": 20, "color" : "green" },
  { "x_axis": 70, "y_axis": 70, "radius": 20, "color" : "purple"},
  { "x_axis": 110, "y_axis": 100, "radius": 20, "color" : "red"}];

var circles = svg.selectAll("circle")
                 .data(jsonCircles)
                 .enter()
                 .append("circle");

var circleAttributes = 
  circles
       // .attr("cx", function (d) { return d.x_axis; })
       // .attr("cy", function (d) { return d.y_axis; })
       .attr("transform", function (d, i) { 
       			return "translate(" + d.x_axis + "," + d.y_axis + ")"; 
       	})
       .attr("r", function (d) { return d.radius; })
       .style("fill", function(d) { return d.color; });



// contiunes to be offset from the cursor by it's original position on drag?
// why is that?
svg.selectAll("circle").call(drag);


// aah ok now it works.
// now I am always setting position using an SVG transform.




var data = [
	{x: 20, y: 20, text:"hello world!"}
]

var text_objects = svg.selectAll("text")
                      .data(data)
                      .enter()
                      .append("text");

text_objects.attr("transform", function (d, i) { 
            	return "translate(" + d.x + "," + d.y + ")"; 
            })
            // .attr("x", function (d) { return d.x; })
            // .attr("y", function (d) { return d.y; })
            .text(function(d){ return d.text })

svg.selectAll("text").call(drag);
// ok... well dragging text doesn't work quite as well as with the circles.
// maybe transform doesn't play nice with svg text?


// function(d){
// 	var x = d3.event.x;
// 	var y = d3.event.y;
// 	d3.select(this)
// 		.attr("x", x)
//         .attr("y", y)
// });




d3.json('api/foo2.json', function(err, data){
  console.log("foo2.json callback")
  svg.selectAll("json_data")
  // ^ not an HTML tag name, but a name you want to give this data
     .data(data)
     .enter()
       .append("circle")
         .attr("transform", function(d){ return "translate(" + d.x + "," + d.y + ")"; }  )
         .attr("r", "10")
         .attr("class", "dot")
         .style("cursor", "pointer")
         .call(drag);
})
// var circles = svg.selectAll("circle")
//                           .data(jsonCircles)
//                           .enter()
//                           .append("circle");


// sketch out just dumping the data from the backend on the canvas
// var computer_science_api = 'api/required_courses/ComputerScienceBS';
// d3.json(computer_science_api, function(err, data){
//   console.log("CS BS callback")
  
//   svg.selectAll("CS BS")
//   // ^ not an HTML tag name, but a name you want to give this data
//      .data(data)
//      .enter()
//        .append("text")
//          .attr("transform", function (d, i) { 
//             var a = Math.floor((100 + i*20) / canvas.height)
//             var y = ((100 + i*20) % canvas.height);
//             var x = 10 + 80 * a ;
//             return "translate(" + x + "," + y + ")"; 
//          })
//          .text(function(d){ return d.id })
//          .style("cursor", "pointer")
//          .call(drag);
// })





var program_of_study = '/api/program_of_study/CS_BS';


// src: http://stackoverflow.com/questions/808826/draw-arrow-on-canvas-tag
function canvas_arrow(context, fromx, fromy, tox, toy){
    var headlen = 10;   // length of head in pixels
    var angle = Math.atan2(toy-fromy,tox-fromx);
    context.moveTo(fromx, fromy);
    context.lineTo(tox, toy);
    context.lineTo(tox-headlen*Math.cos(angle-Math.PI/6),toy-headlen*Math.sin(angle-Math.PI/6));
    context.moveTo(tox, toy);
    context.lineTo(tox-headlen*Math.cos(angle+Math.PI/6),toy-headlen*Math.sin(angle+Math.PI/6));
}


// // variables to control debug printing
var tick = 0
var tick_threshold = 50
// -----------



// code below taken d3v4 example code
// src: http://bl.ocks.org/mbostock/ad70335eeef6d167bc36fd3c04378048
// (starting to make my own modifications slowly over time)
var canvas  = document.querySelector("canvas"),
    context = canvas.getContext("2d"),
    width   = canvas.width,
    height  = canvas.height;





var json_data;
d3.json(program_of_study, function(error, data){
  if (error) throw error;
  
  json_data = data;
  generateGraph(json_data, 1);
});

var simulation;
function generateGraph(data, i) {
  simulation = d3.forceSimulation()
      .force("link", d3.forceLink().id(function(d) { return d.id; }))
      .force("charge", d3.forceManyBody())
      .force("center", d3.forceCenter(width / 2, height / 2));
  
  
  
  data.length;
  
  graph = data[i];
  
  simulation
      .nodes(graph.nodes)
      .on("tick", ticked);
  
  simulation.force("link")
      .links(graph.links);
  
  d3.select(canvas)
      .call(d3.drag()
          .container(canvas)
          .subject(dragsubject)
          .on("start", dragstarted)
          .on("drag", dragged)
          .on("end", dragended));
  
  function ticked() {
    context.clearRect(0, 0, width, height);
    
    context.fillText(
      "Graph 1 is an overview (may be slow). Others are slices.",
      30, 55
    );
    
    page_count = "Graph " + (i+1) + " of " + data.length;
    context.fillText(page_count, 30, 75);
    
    context.fillText("Name: " + graph.name, 30, 95);
    
    
    
    context.beginPath();
    graph.links.forEach(drawLink);
    context.strokeStyle = '#3399FF';
    if(tick < tick_threshold){
      console.log("standard context");
      console.log(context);
      tick += 1;
    }
    context.stroke();
      // ^ batch and render. just like OpenGL.
      //   set state, and then consume it.
    
    
    
    context.beginPath();
    graph.nodes.forEach(drawNode);
    context.fillStyle = '#000' // color of circles
    context.fill();
    context.strokeStyle = "#fff";
    context.stroke();
  }

  function dragsubject() {
    return simulation.find(d3.event.x, d3.event.y);
  }
}

function dragstarted() {
  if (!d3.event.active) simulation.alphaTarget(0.3).restart();
  d3.event.subject.fx = d3.event.subject.x;
  d3.event.subject.fy = d3.event.subject.y;
}

function dragged() {
  d3.event.subject.fx = d3.event.x;
  d3.event.subject.fy = d3.event.y;
}

function dragended() {
  if (!d3.event.active) simulation.alphaTarget(0);
  d3.event.subject.fx = null;
  d3.event.subject.fy = null;
}

function drawLink(d) {
  // context.moveTo(d.source.x, d.source.y);
  // context.lineTo(d.target.x, d.target.y);
  
  
  v1 = $V([d.source.x, d.source.y]);
  v2 = $V([d.target.x, d.target.y]);
  displacement = v2.subtract(v1);
  
  r = 5 // this 'r' should be greater than the 'r' for each node
  // NOTE: maybe the displacement from each end is dependent on the size of the node at that end? that gets pretty complicated though...
    // but ultimately, what I want is to be able to dodge the circle
  difference = displacement.toUnitVector().multiply(r)
  v1 = v1.add(difference);
  v2 = v2.subtract(difference);
  
  canvas_arrow(
    context,
    v1.elements[0], v1.elements[1],
    v2.elements[0], v2.elements[1]
  );
  
  // canvas_arrow(
  //   context,
  //   d.source.x, d.source.y,
  //   d.target.x, d.target.y
  // );
  
  // context.strokeStyle = d.color;
  // context.stroke();
    // ^ if you render here,
    //   don't get any AA, and lines seem oddly thick
  if(tick < tick_threshold){
    console.log("link context");
    console.log(context);
    tick += 1;
  }
  
  // canvas_arrow(
  //   context,
  //   d.target.x, d.target.y,
  //   d.source.x, d.source.y
  // );
  
  
  // NOTE: some co-requisites are listed on both pages, and some are not
}

function drawNode(d) {
  r = 3
  context.moveTo(d.x + r, d.y);
  context.arc(d.x, d.y, r, 0, 2 * Math.PI);
  
  // context.fillStyle = 'f00';
  context.fillStyle = d.color; // color of text (anywhere, this fx)
  context.fillText(d.id, d.x, d.y);
  
  // NOTE: text seems to be rendering behind the circle, not sure why. Order of render commands does not seem to change anything.
  
  
  // NOTE: the color if the first node seems to bleed into all other circles.
    // NO
    // it is not the FIRST one, but the LAST one
  
  
  
  // TODO: figure out how setting context variables effects rendering. I thought I understood it, but I can't always predict future effects, so I clearly don't...
}




// input parsing adapted from the following example
// src: https://bl.ocks.org/eesur/9910343
function handleClick(event){
    console.log(document.getElementById("myVal").value)
    draw(document.getElementById("myVal").value)
    return false;
}

function draw(val){
    i = +val; // in javascript, unary plus coerces to int
    // src: http://stackoverflow.com/questions/1133770/how-do-i-convert-a-string-into-an-integer-in-javascript
    i--;
    generateGraph(json_data, i);
}
