window.addEventListener("load", function(){
	const prophunt_roundinfo = document.getElementById('prophunt-roundinfo');
	const prophunt_roundinfo_msg = document.getElementById('prophunt-roundinfo-msg');
	const prophunt_tutorial = document.getElementById('prophunt-tutorial');
	const prophunt_tutorial_seeker = document.getElementById('prophunt-tutorial-seeker');
	const prophunt_tutorial_props = document.getElementById('prophunt-tutorial-props');

	window.setRoundInfo = (msg) => {
		prophunt_roundinfo_msg.innerHTML = msg;
	};

	window.showRoundInfo = (bool = true) => {
		if(bool)
			prophunt_roundinfo.style.display = 'block';
		else
			prophunt_roundinfo.style.display = 'none';
	};

	window.showTutorial = (bool = true, type = 'props') => {
		if(bool) {
			prophunt_tutorial.style.display = 'block';
			if(type == 'seeker') {
				prophunt_tutorial_seeker.style.display = 'block';
				prophunt_tutorial_props.style.display = 'none';
			}else{
				prophunt_tutorial_seeker.style.display = 'none';
				prophunt_tutorial_props.style.display = 'block';
			}
		}
		else{
			prophunt_tutorial.style.display = 'none';
		}
	};

    setRoundInfo('hallo du');
    showRoundInfo(true);
    showTutorial(true, 'seeker');
});