window.addEventListener("load", function(){

	window.setRoundInfo = (seeker, hider, spectator, state, timer) => {
		let seekerCount = document.getElementById('prophunt-seeker-count');
		let hiderCount = document.getElementById('prophunt-hider-count');
		let specCount = document.getElementById('prophunt-spectator-count');
		let roundState = document.getElementById('prophunt-roundstate');
		let roundTimer = document.getElementById('prophunt-roundtimer');
		seekerCount.innerHTML = seeker;
		hiderCount.innerHTML = hider;
		specCount.innerHTML = spectator + ' spectator';
		roundState.innerHTML = state;
		roundTimer.innerHTML = timer;
	};

	window.setUserMessage = (msg) => {
		let userTutorial = document.getElementById('prophunt-tutorial');
		let userMessage = document.getElementById('prophunt-usermessage');
		if (msg == '')
			userTutorial.style.display = 'none';
		else
			userTutorial.style.display = 'block';
		userMessage.innerHTML = msg;
	};

	window.setUserTeam = (teamID) => {
		// 0 = TeamNeutral
		// 1 = Team1
		// 2 = Team2
		let seekerBadge = document.getElementById('prophunt-seeker-badge');
		let hiderBadge = document.getElementById('prophunt-hider-badge');
		// delete all classes
		seekerBadge.className = '';
		hiderBadge.className = '';
		// add default class
		seekerBadge.classList.add('badge');
		hiderBadge.classList.add('badge');
		// set class depending on team
		switch (teamID) {
			case 1:
				seekerBadge.classList.add('badge-success');
				hiderBadge.classList.add('badge-danger');
				break;
			case 2:
				seekerBadge.classList.add('badge-danger');
				hiderBadge.classList.add('badge-success');
				break;
			default:
				seekerBadge.classList.add('badge-secondary');
				hiderBadge.classList.add('badge-secondary');
		}
	};
});