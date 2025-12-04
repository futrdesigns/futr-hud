function show_hud() {$("body").fadeIn(300)}
function hide_hud() {$("body").fadeOut(300)}
function show_speedometer(status) {
	if(status){
		$(".weapon_box").addClass("inCar")
		$(".speedometer").fadeIn(300, function(){});
		$(".speedometer .speed-items").animate({ opacity: 1 }, 300);
	}
	else{
		$(".speedometer").fadeOut(300, function(){$(".weapon_box").removeClass("inCar")});
		$(".speedometer .speed-items").animate({ opacity: 0 }, 300);
	}
}

function show_weapon(status){
	if(status){$(".weapon_box").fadeIn(300)}
	else{$(".weapon_box").fadeOut(300)}
}

function health(num){$(".health .fill").attr("style","height:"+num+"%");$(".health p.px").text(num+"%")}
function armour(num){$(".armour .fill").attr("style","height:"+num+"%");$(".armour p.px").text(num+"%")}
function food(num){$(".food .fill").attr("style","height:"+num+"%");$(".food p.px").text(num+"%")}
function water(num){$(".water .fill").attr("style","height:"+num+"%");$(".water p.px").text(num+"%")}

function speed(num) {
    $({ numberValue: $(".speed p").text() }).animate({ numberValue: num }, {
        duration: 200,
        easing: 'swing',
        step: function () {
            $(".speed p").text(Math.ceil(this.numberValue));
        }
    });
}
function engine(num) {$(".engine .fill").attr("style","height:"+num+"%");$(".engine p.px").text(num+"%")}
function fuel(num){$(".fuel .fill").attr("style","height:"+num+"%");$(".fuel p.px").text(num+"%")}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function getTimezoneOffset(timezone) {
    const timezones = {
        'GMT': 0, 'UTC': 0, 'BST': 1,
        'EST': -5, 'EDT': -4,
        'CST': -6, 'CDT': -5,
        'MST': -7, 'MDT': -6,
        'PST': -8, 'PDT': -7,
        'AKST': -9, 'AKDT': -8,
        'HST': -10,
        'CET': 1, 'CEST': 2,
        'EET': 2, 'EEST': 3,
        'JST': 9,
        'AEST': 10, 'AEDT': 11
    };
    return timezones[timezone.toUpperCase()] || 0;
}

let clockInterval = null;
let clockConfig = {
    timezone: 'GMT',
    format: '24',
    showSeconds: false
};

function updateClock() {
    const now = new Date();
    const offset = getTimezoneOffset(clockConfig.timezone);
    
    const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
    const targetTime = new Date(utc + (3600000 * offset));
    
    let hours = targetTime.getHours();
    const minutes = targetTime.getMinutes();
    const seconds = targetTime.getSeconds();
    let ampm = "";
    
    if (clockConfig.format === '12') {
        ampm = hours >= 12 ? " PM" : " AM";
        hours = hours % 12;
        if (hours === 0) hours = 12;
    }
    
    let timeString = String(hours).padStart(2, '0') + ':' + String(minutes).padStart(2, '0');
    if (clockConfig.showSeconds) {
        timeString += ':' + String(seconds).padStart(2, '0');
    }
    timeString += ampm;
    
    $("#clock-time").text(timeString);
}

function startClock(timezone, format, showSeconds) {
    clockConfig = { timezone, format, showSeconds };
    
    if (clockInterval) {
        clearInterval(clockInterval);
    }
    
    updateClock();
    
    clockInterval = setInterval(updateClock, 1000);
}

window.addEventListener('message', (event) => {
	const status = event.data.status
	const data = event.data.data
	
	if (status == "info"){
		health(data.health.toFixed(0))
		armour(data.armour.toFixed(0))
		food(data.food.toFixed(0))
		water(data.water.toFixed(0))
	}
	
	if (status == "visible"){
		if (data){show_hud()}
		else{hide_hud()}
	}
	
	if (status == "speedometer"){
		const visible = data.visible
		if (!visible){
			show_speedometer(false)
			return
		}
		if (visible){
			show_speedometer(true)
		}
		const speed_num = data.speed.toFixed(0)
		const engine_num = data.engine.toFixed(0)
		const fuel_num = data.fuel.toFixed(0)
		if (data.mph){
			$(".speed span").text("mph")
		} else {
			$(".speed span").text("km/h")
		}
		speed(speed_num)
		engine(engine_num)
		fuel(fuel_num)
	}
	
	if (status == "weapon"){
		if (!data.visible){
			show_weapon(false)
			return
		}
		if (data.visible){
			show_weapon(true)
		}
		$(".weapon .fill").attr("style","height:"+(data.ammoInClip/data.maxAmmo)*100+"%")
		$(".weapon p.px").text(`${data.ammoInClip}/${data.totalAmmo}`)
	}
	
	if (status == "playerinfo"){
		$("#player-id").text(data.id)
		
		let jobText = data.job
		if (jobText.length > 25) {
			jobText = jobText.substring(0, 25) + "..."
		}
		$("#player-job").text(jobText)
		
		if (data.cash > 0) {
			$(".cash-item").show()
			$("#player-cash").text(formatNumber(data.cash))
		} else {
			$(".cash-item").hide()
		}
		
		if (data.bank > 0) {
			$(".bank-item").show()
			$("#player-bank").text(formatNumber(data.bank))
		} else {
			$(".bank-item").hide()
		}
	}
	
	if (status == "voice"){
		const voiceItem = $(".voice-item")
		const voiceIcon = $("#voice-icon")
		
		if (data.talking) {
			voiceItem.addClass("talking")
		} else {
			voiceItem.removeClass("talking")
		}
		
		switch(data.mode) {
			case 1:
				$("#voice-range").text("Whisper")
				break
			case 2:
				$("#voice-range").text("Normal")
				break
			case 3:
				$("#voice-range").text("Shouting")
				break
			default:
				$("#voice-range").text("Normal")
		}
	}
	
	if (status == "location"){
		$("#location-street").text(data.street)
		$("#location-area").text(data.area)
		$("#direction").text(data.direction)
	}
	
	if (status == "seatbelt"){
		const seatbeltIndicator = $(".item.seatbelt-indicator")
		
		if (data.show) {
			seatbeltIndicator.addClass("show")
			
			seatbeltIndicator.removeClass("on warn")
			
			if (data.on) {
				seatbeltIndicator.addClass("on")
			} else if (data.warn) {
				seatbeltIndicator.addClass("warn")
			}
		} else {
			seatbeltIndicator.removeClass("show on warn")
		}
	}
	
	if (status == "requestTime"){
		startClock(data.timezone, data.format, data.showSeconds)
	}
	
	if (status == "clock"){
		$("#clock-time").text(data.time)
	}
})
