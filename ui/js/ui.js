window.addEventListener("load", function(){

	window.setRoundInfo = (player, seeker, hider, spectator, state, timer) => {
		let playerCount = document.getElementById('prophunt-totalplayers-count');
		let seekerCount = document.getElementById('prophunt-seeker-count');
		let hiderCount = document.getElementById('prophunt-hider-count');
		let specCount = document.getElementById('prophunt-spectator-count');
		let roundState = document.getElementById('prophunt-roundstate');
		let roundTimer = document.getElementById('prophunt-roundtimer');
		playerCount.innerHTML = player;
		seekerCount.innerHTML = seeker;
		hiderCount.innerHTML = hider;
		specCount.innerHTML = spectator + ' spectator';
		roundState.innerHTML = state;
		roundTimer.innerHTML = timer;
	};

	// show or hide WebUI
	window.showHealthBar = (bool) => {
		let healthBar = document.getElementById('prophunt-health-bar');
		if (bool)
			healthBar.style.display = 'block';
		else
			healthBar.style.display = 'none';
	};

	window.setHealthBar = (hp, ammo) => {
		let playerHp = document.getElementById('prophunt-health-bar-hp');
		let playerAmmo = document.getElementById('prophunt-health-bar-ammo');
		playerHp.innerHTML = hp;
		playerAmmo.innerHTML = ammo;
	};

	window.setUserMessage = (msg) => {
		let userMessage = document.getElementById('prophunt-usermessage');
		let userMessageText = document.getElementById('prophunt-usermessage-text');
		if (msg === '')
			userMessage.style.display = 'none';
		else
			userMessage.style.display = 'block';
		userMessageText.innerHTML = msg;
	};

	window.setSpectatorMessage = (msg) => {
		let specMessage = document.getElementById('prophunt-spectator-message');
		let specMessageText = document.getElementById('prophunt-spectator-message-text');
		if (msg === '')
			specMessage.style.display = 'none';
		else
			specMessage.style.display = 'block';
		specMessageText.innerHTML = msg;
	};
	

	window.setCenterMessage = (msg, hideAfter = 10) => {
		let centerMessage = document.getElementById('prophunt-centermessage');
		if (msg === '')
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
		let seekerTitle = document.getElementById('prophunt-roundinfo-seeker-title');
		let hiderTitle = document.getElementById('prophunt-roundinfo-hider-title');
		// delete all classes
		seekerTitle.className = '';
		hiderTitle.className = '';
		// set class depending on team
		switch (teamID) {
			case 1:
				seekerTitle.classList.add('color-green');
				hiderTitle.classList.add('color-red');
				break;
			case 2:
				seekerTitle.classList.add('color-red');
				hiderTitle.classList.add('color-green');
				break;
			default:
				seekerTitle.classList.add('color-gray');
				hiderTitle.classList.add('color-gray');
		}
	};

	// overlay when round is over
	window.postRoundOverlay = (winner, clientTeam) => {
		// client has won so give him a end he deserves
		if (winner == clientTeam || clientTeam === 0) {
			playSound('victory' + (Math.floor(Math.random() * 3) + 1));
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
			playSound('defeated' + (Math.floor(Math.random() * 3) + 1));
		}
	};

	// show or hide Hider keys
	window.showKillfeed = (bool) => {
		let killfeed = document.getElementById('prophunt-killfeed');
		if (bool)
			killfeed.style.display = 'block';
		else
			killfeed.style.display = 'none';
	};

	// add element to killfeed
	window.addToKillfeed = (name, team, type) => {
		let killfeed = document.getElementById('prophunt-killfeed');
		let killfeedList = document.getElementById('prophunt-killfeed-list');
		// do nothing when killfeed is not visible
		if (killfeed.style.display == 'none') return;
		// create li element
		let li = document.createElement('li');
		let text = '';
		switch(type) {
			case 'kill':
				switch(team) {
					case 1:
						text = '[SEEKER] ' + name + ' got killed';
						break;
					case 2:
						text = '[HIDER] ' + name + ' got killed';
						break;
					default:
						text = name + ' got killed';
				}
				break;
			case 'connect':
				text = name + ' joined';
				break;
			case 'disconnect':
				text = name + ' left';
				break;
		}
		li.appendChild(document.createTextNode(text));
		li.classList.add('list-group-item');
		li.classList.add('fade-in');
		// append to killfeed
		killfeedList.appendChild(li);
		// hide after three seconds
		setTimeout(function() {
			li.remove();
		}, 10 * 1000);
	};

	window.playSound = (sound) => {
		var audio = new Audio('./sounds/' + sound + '.mp3');
		audio.play();
	};

	// show or hide Hider keys
	window.showHiderKeys = (bool) => {
		let hiderKeys = document.getElementById('prophunt-hider-keys');
		if (bool)
			hiderKeys.style.display = 'block';
		else
			hiderKeys.style.display = 'none';
	};

	// show or hide spectator keys
	window.showSpectatorKeys = (bool) => {
		let spectatorKeys = document.getElementById('prophunt-spectator-keys');
		if (bool)
			spectatorKeys.style.display = 'block';
		else
			spectatorKeys.style.display = 'none';
	};

	// show or hide WebUI
	window.showUI = (bool) => {
		let body = document.body;
		if (bool)
			body.style.display = 'block';
		else
			body.style.display = 'none';
	};

	// show or hide scoreboard
	window.showScoreboard = (bool) => {
		let scoreboard = document.getElementById('prophunt-scoreboard');
		if (bool)
			scoreboard.style.display = 'block';
		else
			scoreboard.style.display = 'none';
	};

	// show or hide idle round message
	window.showWelcomeMessage = (bool) => {
		let idleStateMessage = document.getElementById('prophunt-welcomemessage');
		if (bool)
			idleStateMessage.style.display = 'block';
		else
			idleStateMessage.style.display = 'none';
	};

	// update scoreboard
	window.updateScoreboard = (data, clientTeam) => {
		let scoreboardListSeeker = document.getElementById('prophunt-scoreboard-list-seeker');
		let scoreboardListSeekerSmall = document.getElementById('prophunt-scoreboard-list-seeker-small');
		let scoreboardListHider = document.getElementById('prophunt-scoreboard-list-hider');
		let scoreboardListHiderSmall = document.getElementById('prophunt-scoreboard-list-hider-small');
		let scoreboardListSpectator = document.getElementById('prophunt-scoreboard-list-spectator');
		let idlelistSpectator = document.getElementById('prophunt-welcomemessage-players');
		scoreboardListSeeker.innerHTML = '';
		scoreboardListSeekerSmall.innerHTML = '';
		scoreboardListHider.innerHTML = '';
		scoreboardListHiderSmall.innerHTML = '';
		scoreboardListSpectator.innerHTML = '';
		idlelistSpectator.innerHTML = '';
		// sort data by living players first
		data.sort(function(a, b){
			if (!a.alive && b.alive) {
				return -1;
			} else if (a.alive && !b.alive) {
				return 1;
			}   
			return 0;
		});
		// populate scoreboard
		var i;
		var count_seeker = 0;
		var count_hider = 0;
		for (i = 0; i < data.length; i++) {
			let row = null;
			let cell1 = null;
			let button = null;
			// create complete player list for idle round players list
			button = document.createElement('button');
			button.appendChild(document.createTextNode(data[i].username));
			button.classList.add('btn');
			button.classList.add('btn-secondary');
			button.classList.add('m-1');
			idlelistSpectator.appendChild(button);
			// switch between player teams
			switch(data[i].team) {
				case 1:
					count_seeker += 1;
					// only display first 10 people in large view
					if(count_seeker <= 10) {
						row = scoreboardListSeeker.insertRow(0);
						cell1 = row.insertCell(0);
						cell1.innerHTML = data[i].username;
						if (!data[i].alive)	cell1.classList.add('dead');
					}else{	// display other ones as small buttons after the table
						button = document.createElement('button');
						button.appendChild(document.createTextNode(data[i].username));
						button.classList.add('btn');
						button.classList.add('btn-secondary');
						button.classList.add('btn-sm');
						button.classList.add('m-1');
						scoreboardListSeekerSmall.appendChild(button);
					}
					break;
				case 2:
					count_hider += 1;
					// only display first 10 people in large view
					if(count_hider <= 10) {
						row = scoreboardListHider.insertRow(0);
						cell1 = row.insertCell(0);
						cell1.innerHTML = data[i].username;
						if (!data[i].alive)	cell1.classList.add('dead');
					}else{	// display other ones as small buttons after the table
						button = document.createElement('button');
						button.appendChild(document.createTextNode(data[i].username));
						button.classList.add('btn');
						button.classList.add('btn-secondary');
						button.classList.add('btn-sm');
						button.classList.add('m-1');
						scoreboardListHiderSmall.appendChild(button);
					}
					break;
				default:
					// create spectator button
					button = document.createElement('button');
					button.appendChild(document.createTextNode(data[i].username));
					button.classList.add('btn');
					button.classList.add('btn-secondary');
					button.classList.add('m-1');
					scoreboardListSpectator.appendChild(button);
			}
		}
	};
});