kxchange = function(id,num) {//{{{
    var name = document.getElementById(id);
    var span = name.getElementsByTagName("span");
    for(var i=0;i<span.length;i++){
        span[i].className = "sp"+i;
        document.getElementById(id+"_ul_"+i).style.display = "none";
    }
    span[num].className = "sp"+num+num;
    document.getElementById(id+"_ul_"+num).style.display = "block";
}//}}}

