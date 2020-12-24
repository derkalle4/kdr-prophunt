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
	window.setCenterMessage = (msg, hideAfter = 10) => {
		let centerMessage = document.getElementById('prophunt-centermessage');
		if (msg == '')
			centerMessage.style.display = 'none';
		else{
			centerMessage.style.display = 'block';
			// hide message after X seconds
			setTimeout(function() {
				let centerMessage = document.getElementById('prophunt-centermessage');
				centerMessage.style.display = 'none';
			}, hideAfter * 1000);
		}
		centerMessage.innerHTML = msg;
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
	// overlay when round is over
	window.postRoundOverlay = (winner, clientTeam) => {
		// client has won so give him a end he deserves
		if (clientTeam == 0) {
			// do nothing for spectator for now
		}else if (winner == clientTeam) {
			playSound('victory' + (Math.floor(Math.random() * 2) + 1));
			var confettiSettings = {
				target: 'confetti-canvas',
				width: window.innerWidth - 10,
				height: window.innerHeight - 10
			};
			var confetti = new ConfettiGenerator(confettiSettings);
			confetti.render();
			// hide confetti after 15 seconds
			setTimeout(function() {
				confetti.clear();
			}, 15 * 1000);
		}else{
			playSound('defeated' + (Math.floor(Math.random() * 2) + 1));
		}
	};

	window.playSound = (sound) => {
		var audio = new Audio('./sounds/' + sound + '.mp3');
		audio.play();
	};

	// update scoreboard
	window.updateScoreboard = (data, clientTeam) => {
		var i;
		// populate scoreboard
		for (i = 0; i < data.length; i++) {
			let scoreboardList = document.getElementById('prophunt-scoreboard-list');
			scoreboardList.innerHTML = '';
			let li = document.createElement("li");
			// set content
			li.appendChild(document.createTextNode(data[i].username));
			li.classList.add('list-group-item');
			// set class
			switch(clientTeam) {
				case 1:
					if (data[i].team == 1 && data[i].alive == true) scoreboardList.appendChild(li);
					break;
				case 2:
					if (data[i].team == 2 && data[i].alive == true) scoreboardList.appendChild(li);
					break;
				default:
					scoreboardList.appendChild(li);
			}
			if (i == 9) break;
		}
		// set scoreboard title
		let scoreboardTitle = document.getElementById('prophunt-scoreboard-title');
		switch(clientTeam) {
			case 1:
				scoreboardTitle.innerHTML = 'Alive Seekers';
				break;
			case 2:
				scoreboardTitle.innerHTML = 'Alive Hiders';
				break;
			default:
				scoreboardTitle.innerHTML = 'All Players';
		}
	}
});