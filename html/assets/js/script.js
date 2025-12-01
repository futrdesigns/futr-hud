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
		
		$("#player-cash").text(formatNumber(data.cash))
		$("#player-bank").text(formatNumber(data.bank))
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
		const seatbeltIndicator = $(".seatbelt-indicator")
		
		if (data.show) {
			seatbeltIndicator.addClass("show")
			
			if (data.on) {
				seatbeltIndicator.addClass("on")
				seatbeltIndicator.removeClass("warn")
			} else if (data.warn) {
				seatbeltIndicator.removeClass("on")
				seatbeltIndicator.addClass("warn")
			} else {
				seatbeltIndicator.removeClass("on")
				seatbeltIndicator.removeClass("warn")
			}
		} else {
			seatbeltIndicator.removeClass("show")
			seatbeltIndicator.removeClass("on")
			seatbeltIndicator.removeClass("warn")
		}
	}
})
