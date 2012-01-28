function MM_swapImgRestore() { //v3.0
	var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}
function MM_preloadImages() { //v3.0
	var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
		var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
		if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
	}

	function MM_findObj(n, d) { //v4.01
		var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
			d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
			if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
			for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
			if(!x && d.getElementById) x=d.getElementById(n); return x;
		}

		function MM_swapImage() { //v3.0
			var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
			if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
		}
		
// show selected tab
$(document).ready(function(){			
	// show selected tab
 $('.vtag_video').parents().find('#vtag_video a').removeClass('fbtab').addClass('fbtab_selected')
 $('.got_vtag').parents().find('#got_vtag a').removeClass('fbtab').addClass('fbtab_selected')
 $('.upload_video').parents().find('#upload_video a').removeClass('fbtab').addClass('fbtab_selected')
 $('.about_vtago').parents().find('#about_vtag a').removeClass('fbtab').addClass('fbtab_selected')
 
 
 /
 
 //fb form upload validations
	
	$("#upload_fb_video").click(function(){
		if (fb_upload_validation()){
			//submit form		
		$("form:first").submit();
		// display the loading div+mask until the form is submitted
		display_loading_mask();
		}
	});	
	
	function display_loading_mask(){
		//Get the screen height and width
        var maskHeight = $(document).height();
        var maskWidth = $(window).width();
     
        //Set height and width to mask to fill up the whole screen
        $('#mask').css({'width':maskWidth,'height':maskHeight});
        //transition effect   
      
        $('#mask').fadeIn(1000);    
        $('#mask').fadeTo("slow",0.8);        
        display_loading_div() // display on the mask the loading div
      
	}
	
	function display_loading_div(){
		//Get the window height and width
        var top=($(window).height()-$("#dialog").height())/2;
         var left=($(window).width()-$("#dialog").width())/2;
               
        //Set the popup window to center;       
        $('#dialog').css('top',top);
        $('#dialog').css('left',left); 
        //transition effect
        $('#dialog').fadeIn(2000);         
	}
	
	function fb_upload_validation(){
		var ext = $('#fb_upload_file').val().split('.').pop(); //finds the file extensions
		var keys = $('#fb_keywords').val().split(" "); //splits the keywords by spaces
		
		//check if upload file is empty
		if ($("#fb_upload_file").val()==''){
			$("#fb_file_upload_error").text("Source file name can't be empty");
			$("#fb_file_upload_error").show();
			$("#fb_upload_file").addClass('error');			
		}
		//check if the upload file has the correct extension
		else if(ext!="MOV" && ext!="AVI"){	
			$("#fb_file_upload_error").text("Incorrect file extension");
			$("#fb_file_upload_error").show();		
			$("#fb_upload_file").addClass('error')
		}	
	   else{					
			$("#fb_file_upload_error").hide();
			$("#fb_upload_file").removeClass('error')			
		}
		
		//check if title is empty
		if ($("#fb_title").val()==''){
			$("#fb_title_error").text("Title can't be empty");
			$("#fb_title_error").show();
			$("#fb_title").addClass('error')
		}
		else{
			$("#fb_title_error").hide();
			$("#fb_title").removeClass('error')			
		}
		
		//check if kewords are in a correct format		
		if ($('#fb_keywords').val()!='' && keys.length>1){ // if find words with a space between them
			$('#fb_keywords_error').text("Keyword should be separated with ',' between them");
			$('#fb_keywords_error').show();
			$("#fb_keywords").addClass('error')
		}
		else{
			$("#fb_keywords_error").hide();
			$("#fb_keywords").removeClass('error')		
		}
		
		if ($("#fb_title").hasClass('error')||$("#fb_upload_file").hasClass('error')||$("#fb_keywords").hasClass('error')){
			return false
		}
		else{
			return true
		}
				
	}
	
});
