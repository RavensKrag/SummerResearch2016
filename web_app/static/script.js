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
var computer_science_api = 'api/required_courses/ComputerScienceBS';
d3.json(computer_science_api, function(err, data){
  console.log("CS BS callback")
  
  svg.selectAll("CS BS")
  // ^ not an HTML tag name, but a name you want to give this data
     .data(data)
     .enter()
       .append("text")
         .attr("transform", function (d, i) { 
            var a = Math.floor((100 + i*20) / canvas.height)
            var y = ((100 + i*20) % canvas.height);
            var x = 10 + 80 * a ;
            return "translate(" + x + "," + y + ")"; 
         })
         .text(function(d){ return d.id })
         .style("cursor", "pointer")
         .call(drag);
})
