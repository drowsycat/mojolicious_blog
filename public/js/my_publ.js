var max_menu=5000;

var menu_array=new Array();
for (i=0; i<=max_menu; i++){
        menu_array[i]=0;
}

var select_method; //DOM type
var nn=false;
var domb=false;
var msie=false;

function set_browser(){
        if (document.getElementById){
                select_method="getElementById";
                domb=!domb;

        }
        else if (document.all){
                select_method="all";
                msie=!msie

        }
        else if (document.layers){
                nn=!nn;
        }
        else {
                alert("Browser is not defined!");
        }
}

set_browser();

function set_visible_ie(div_id){
        eval("document."+select_method+"('id"+div_id+"').style.visibility='visible'");
        eval("document."+select_method+"('id"+div_id+"').style.position='relative'");
        eval("document."+select_method+"('id"+div_id+"').style.top='0px'");
        
}

function set_hide_ie(div_id){
        eval("document."+select_method+"('id"+div_id+"').style.visibility='hidden'");
        eval("document."+select_method+"('id"+div_id+"').style.position='absolute'");
        eval("document."+select_method+"('id"+div_id+"').style.top='-2000px'");
        
}

function get_visible_ie(div_id){
        eval("document."+select_method+"('id"+div_id+"').style.visibility='visible'");
        eval("document."+select_method+"('id"+div_id+"').style.position='relative'");
        eval("document."+select_method+"('id"+div_id+"').style.top='0px'");
        
}

function get_hide_ie(div_id){
        eval("document."+select_method+"('id"+div_id+"').style.visibility='hidden'");
        eval("document."+select_method+"('id"+div_id+"').style.position='absolute'");
        eval("document."+select_method+"('id"+div_id+"').style.top='-2000px'");
        
}

function set_change(div_id){
        if ((domb)||(msie)){
                if (menu_array[div_id]==0){
                        set_visible_ie(div_id);
                        menu_array[div_id]=1;
                }
                else {
                        set_hide_ie(div_id);
                        menu_array[div_id]=0;
                }
        }
}

////////////////////////////////////////////////////////////////////////
function get_change(div_id){
        if ((domb)||(msie)){
                if (menu_array[div_id]==0){
                        get_visible_ie(div_id);
                        menu_array[div_id]=1;
                }
                else {
                        get_hide_ie(div_id);
                        menu_array[div_id]=0;
                }
        }
}
///////////////////////////////////////////////////////////////////////////

function show_block(div_id){
        if (!nn){
                eval("document."+select_method+"('"+div_id+"').style.visibility='visible'");
                eval("document."+select_method+"('"+div_id+"').style.position='relative'");
                eval("document."+select_method+"('"+div_id+"').style.top='0px'");
                }
        }

/////////////////////////////////////////// 

var limit = 300; // в секундах
function processTimer(){
  if (limit > 0) {
    setTimeout("processTimer()",1000);
    limit--;
  } else {
    // здесь действия после завершения таймера
    //..
  }
  var limit_div = parseInt(limit/60); // минуты
  var limit_mod = limit - limit_div*60; // секунды
  // строка с оставшимся временем
  limit_str = "&nbsp;";
  if (limit_div < 10) limit_str = limit_str + "0";
  limit_str = limit_str + limit_div + ":";
  if (limit_mod < 10) limit_str = limit_str + "0";
  limit_str = limit_str + limit_mod + "&nbsp;";      
  // вывод времени
  el_timer = document.getElementById("timer");
  if (el_timer) el_timer.innerHTML = limit_str;
}

///////////////////////////////////////////////////////// 

var limit2 = 1800; // в секундах
function processTimer2(){
  if (limit2 > 0) {
    setTimeout("processTimer2()",1000);
    limit2--;
  } else {
    // здесь действия после завершения таймера
    //..
  }
  var limit_div2 = parseInt(limit2/60); // минуты
  var limit_mod2 = limit2 - limit_div2*60; // секунды
  // строка с оставшимся временем
  limit_str2 = "&nbsp;";
  if (limit_div2 < 10) limit_str2 = limit_str2 + "0";
  limit_str2 = limit_str2 + limit_div2 + "m ";
  if (limit_mod2 < 10) limit_str2 = limit_str2 + "0";
  limit_str2 = limit_str2 + limit_mod2 + "s";      
  // вывод времени
  el_timer2 = document.getElementById("timer2");
  if (el_timer2) el_timer2.innerHTML = limit_str2;
}

/////////////////////////////////////////////////////
var MaxLen = 1500;
var mclick = 0;
var texttyped = 0;
if (!document.all){
   texttyped=1;
}


function onTypeChar() {
 texttyped=1;
 var frm=document.cmntf;
 var elem=frm.comment;
 inputStr = elem.value;
 strlength= inputStr.length;
 if (strlength > MaxLen ) elem.value=inputStr.substring(0,MaxLen);
 frm.lastchar.value = (MaxLen - elem.value.length);
 elem.focus();
}

function onClickMes(msg){
 var frm=document.cmntf;
 var elem=frm.comment;
 if (mclick==0 && elem.value == msg){
    elem.value='';
 }
 mclick=1;
 elem.focus();
}
//////////////////////////////////////////////////////////

function navigPublic(thisLink){
var mainDir='/publication/'
var newCont=""
var NavigLink=new Array(5)
var i = 1;
NavigLink[1]='головна'
NavigLink[2]='аналітика'
NavigLink[3]='архіви'
NavigLink[4]='найкраще'
var NavHref=new Array(1)
NavHref[1] = 'show_main.htm'
NavHref[3] = 'archive.htm'

for(i; i<NavigLink.length; i++){
if(NavigLink[i] == thisLink){
newCont+="<td align=right background=/imag/left_corn_nav_actv.gif width=7></td><td>"
newCont+="<DIV id= activ_pg>" + NavigLink[i] + "</DIV></td>"
newCont+="<td align=left background=/imag/right_corn_nav_actv.gif width=7><img src=/imag/none.gif></td>"
newCont+="<td width=3></td>"
}else{
newCont+="<td align=right background=/imag/left_corn_nav.gif width=7></td><td>"
newCont+="<DIV id= unactiv_pg>" + "<A HREF=" + mainDir + NavHref[i] + ">" +  NavigLink[i] + "</A></DIV></td>"
newCont+="<td align=left background=/imag/right_corn_nav.gif width=7><img src=/imag/none.gif></td>"
newCont+="<td width=3></td>"
}
}
document.write(newCont)

}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//FONCTION POUR DOWNLOAD FAQ LINK et BOX ARTICLES
function MontreCacheItems(idImgOpen,idImgClose,idDivItems,idMenuSelect) {
	if((document.getElementById && document.getElementById(idImgOpen).style.display == 'inline') || (document.all && document.all[idImgOpen].style.display == 'inline') || (document.layers && document.layers[idImgOpen].display == 'inline') ) {
		cache(idImgOpen);
		montre(idImgClose,'inline');
		if((document.getElementById && document.getElementById(idDivItems) != null) || (document.all && document.all[idDivItems] != undefined ) || (document.layers && document.layers[idDivItems] != undefined) ) {
			montre(idDivItems,'block');
		} else {
			montre(idMenuSelect,'block');
		}
	} else {
		cache(idImgClose);
		montre(idImgOpen,'inline');
		if((document.getElementById && document.getElementById(idDivItems) != null) || (document.all && document.all[idDivItems] != undefined ) || (document.layers && document.layers[idDivItems] != undefined) ) {
			cache(idDivItems);
		} else {
			cache(idMenuSelect);
		}
	}
}

function montre(id, display) {
  	if (display != 'block' && display != 'inline') display = 'block';
  	if (document.getElementById) {
    	document.getElementById(id).style.display = display;
  	} else if (document.all) {
    	document.all[id].style.display = display;
  	} else if (document.layers) {
    	document.layers[id].display = display;
  	}
}

function cache(id) {
  if (document.getElementById) {
    document.getElementById(id).style.display = 'none';
  }
  else if (document.all) {
    document.all[id].style.display = 'none';
  }
  else if (document.layers) {
    document.layers[id].display = 'none';
  }
}

//////////////////////////////////////////