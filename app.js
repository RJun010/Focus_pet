(() => {
	const studyInput = document.getElementById('studyMinutes');
	const restInput = document.getElementById('restMinutes');
	const cyclesInput = document.getElementById('cycles');
	const startBtn = document.getElementById('startBtn');
	const pauseBtn = document.getElementById('pauseBtn');
	const resetBtn = document.getElementById('resetBtn');
	const timeEl = document.getElementById('time');
	const modeLabel = document.getElementById('modeLabel');
	const cycleInfo = document.getElementById('cycleInfo');
	const ring = document.querySelector('.ring');

	const R = 100;
	const CIRC = 2 * Math.PI * R;
	ring.style.strokeDasharray = `${CIRC} ${CIRC}`;
	ring.style.strokeDashoffset = '0';

	let totalSeconds = 0;
	let remaining = 0;
	let timer = null;
	let isRunning = false;
	let mode = 'idle'; // 'study' | 'rest' | 'idle'
	let cycles = 1;
	let currentCycle = 0;

	function secondsToMMSS(s){
		const mm = Math.floor(s/60).toString().padStart(2,'0');
		const ss = (s%60).toString().padStart(2,'0');
		return `${mm}:${ss}`;
	}

	function updateRing(){
		if (totalSeconds <= 0) {
			ring.style.strokeDashoffset = '0';
			return;
		}
		const progress = (totalSeconds - remaining) / totalSeconds;
		const offset = CIRC * (1 - progress);
		ring.style.strokeDashoffset = offset;
	}

	function updateUI(){
		timeEl.textContent = secondsToMMSS(remaining);
		cycleInfo.textContent = mode === 'idle' ? '' : `Ciclo ${currentCycle} / ${cycles}`;
		modeLabel.textContent = mode === 'study' ? 'Estudio' : (mode === 'rest' ? 'Descanso' : 'Listo');
	}

	function playBeep(){
		try{
			const ctx = new (window.AudioContext || window.webkitAudioContext)();
			const t = ctx.currentTime;
			const o = ctx.createOscillator();
			const g = ctx.createGain();
			o.type = 'sine';
			o.frequency.setValueAtTime(880, t);
			g.gain.setValueAtTime(0, t);
			g.gain.linearRampToValueAtTime(0.5, t + 0.01);
			g.gain.exponentialRampToValueAtTime(0.001, t + 0.6);
			o.connect(g);
			g.connect(ctx.destination);
			o.start(t);
			o.stop(t + 0.7);
		}catch(e){
			// fallback: nothing
		}
	}

	function startCycle(){
		const studyMinutes = Math.max(1, parseInt(studyInput.value) || 25);
		const restMinutes = Math.max(1, parseInt(restInput.value) || 5);
		cycles = Math.max(1, parseInt(cyclesInput.value) || 4);

		if (currentCycle === 0) currentCycle = 1;
		mode = 'study';
		totalSeconds = studyMinutes * 60;
		remaining = totalSeconds;
		updateUI();
		updateRing();
		isRunning = true;
		startInterval(studyMinutes, restMinutes);
		startBtn.disabled = true;
		pauseBtn.disabled = false;
	}

	function startInterval(studyMin, restMin){
		if (timer) clearInterval(timer);
		timer = setInterval(() => {
			if (!isRunning) return;
			remaining--;
			if (remaining < 0) {
				// end of current period
				playBeep();
				if (mode === 'study') {
					// switch to rest
					mode = 'rest';
					totalSeconds = restMin * 60;
					remaining = totalSeconds;
					updateUI();
					updateRing();
				} else if (mode === 'rest') {
					// finished a cycle
					if (currentCycle >= cycles) {
						// finished all cycles
						clearInterval(timer);
						timer = null;
						mode = 'idle';
						isRunning = false;
						startBtn.disabled = false;
						pauseBtn.disabled = true;
						currentCycle = 0;
						totalSeconds = 0;
						remaining = 0;
						updateUI();
						updateRing();
						return;
					} else {
						currentCycle++;
						mode = 'study';
						totalSeconds = studyMin * 60;
						remaining = totalSeconds;
						updateUI();
						updateRing();
					}
				}
			}
			updateUI();
			updateRing();
		}, 1000);
	}

	startBtn.addEventListener('click', () => {
		if (isRunning) return;
		// If we were idle and cycles not started, start fresh
		if (mode === 'idle' || currentCycle === 0) {
			currentCycle = 1;
		}
		// If we've paused mid-period, just resume
		if (remaining > 0 && mode !== 'idle' && !isRunning) {
			isRunning = true;
			startBtn.disabled = true;
			pauseBtn.disabled = false;
			return;
		}
		startCycle();
	});

	pauseBtn.addEventListener('click', () => {
		isRunning = false;
		startBtn.disabled = false;
		pauseBtn.disabled = true;
	});

	resetBtn.addEventListener('click', () => {
		if (timer) { clearInterval(timer); timer = null; }
		isRunning = false;
		mode = 'idle';
		currentCycle = 0;
		totalSeconds = 0;
		remaining = 0;
		startBtn.disabled = false;
		pauseBtn.disabled = true;
		updateUI();
		updateRing();
	});

	// initialize display
	timeEl.textContent = '00:00';
	updateUI();

	// optional: keyboard start (space)
	document.addEventListener('keydown', (e) => {
		if (e.code === 'Space') {
			e.preventDefault();
			if (isRunning) pauseBtn.click(); else startBtn.click();
		}
	});
})();