console.log("hello world")




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
var canvas = {width: 700, height: 400};


// Create the SVG
var svg = d3.select("body").append("svg")
  .attr("width",  canvas.width)
  .attr("height", canvas.height)
  .on("click", click);

// var svg = d3.select("body").select("svg")
//   .attr("width",  canvas.width)
//   .attr("height", canvas.height)
//   .on("click", click);

// Add a background
svg.append("rect")
  .attr("width",  canvas.width)
  .attr("height", canvas.height)
  .style("stroke", "#999999")
  .style("fill", "#F6F6F6")

// Define drag beavior
var drag = d3.drag()
    .on("drag", dragmove);



// console.log("yayaya")









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

var circleAttributes = circles
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
	{x: 20, y: 20, font_family:"sans-serif", font_size:"20px", color:"red", text:"hello world!"}
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
            // .attr("x", function (d) { return d.x; })
            .style("fill", function(d) { return d.color; })
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
  var new_circles = svg
     .data(data)
     .enter()
     .append("circle")
  
  new_circles
        .attr("transform", function(p){ return "translate(" + p.x + "," + p.y + ")"; }  )
        .attr("r", "5")
        .attr("class", "dot")
        .style("cursor", "pointer")
        .call(drag);
})
