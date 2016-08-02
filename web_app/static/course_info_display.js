function course_info_display(course_node){
	// console.log(course_node.name);
	
	name = course_node.name.replace(" ", "_")
	
	d3.json("/api/course_info/" + name, function (error, api_data) {
		if (error) throw error;
		
	    container = d3.select("div#output");
	    
	    // console.log(api_data);
	    
	    container.selectAll("h1")
	             // .data(api_data.id)
	             	.text(api_data.course_id + ": " + api_data.title);
	    
	    container.selectAll(".credits").text(api_data.credits);
	    container.selectAll(".attempts").text(api_data.attempts);
	    container.selectAll(".department").text(api_data.department);
	    
	    
	    
	    container.selectAll(".description")
	    .text(api_data.Description);
	    
	    
	    // container.selectAll("p.description")
	    //          // .data(api_data.id)
	    //          	.text(api_data.course_id + ": " + api_data.title);
	    
	    data = [
	    	// [{"key": ,"value": }]
	    	{"key": "Notes", "value": api_data.Notes}
	    ]
	    // container.select("p.tags ul li.notes .value")
	    // .text(api_data.Notes);
	    
	    
	    // container.selectAll("p.tags ul li").remove();
	    
	    items = 
		    container.select("p.tags ul").selectAll("li")
		    .data(data);
	    
	    // items.enter().append("li")
	    // 	.text("test");
	    
	    
	    
	    foo = items.enter().append("li");
	    
	    foo.append("strong")
	    	.attr("class", "key")
	    	.text(function (d) {
		    	return d.key + ": ";
		    })
    	;
	    foo.append("span")
		    .attr("class", "value")
		    .text(function (d) {
		    	return d.value;
		    })
	    ;
	    foo.append("br")
	    ;
	    
	    
	    
	    
	    items.exit()
	    	.remove();
	});
}
