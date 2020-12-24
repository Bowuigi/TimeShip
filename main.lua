--TimeShip made by Bowuigi

resolution=require "lib/tlfres" --scaling library
moonshine= require "lib/moonshine" --shader library

--screen size (for scaling purposes)
local screen_width=800
local screen_height=600

--gui
ui={
	buttons={
		play={text="Play",x=400,y=300,pressed=false,width=55,height=30,color={255,255,255}}
	},
	text={
		title={text="TimeShip",x=35,y=100}
	}
}

function love.load()
	local mx,my=resolution.getMousePosition(screen_width,screen_height)

	effect=moonshine(screen_width,screen_height,moonshine.effects.glow)
	effect.glow.min_luma=0
	effect.glow.strength=3

	--keybindings
	keys={
		up={"up","w","i"},
		down={"down","s","k"},
		left={"left","a","j"},
		right={"right","d","l"},
		shoot={1,2},
		pause={"p","escape"},
		--debug keybindings
		upgrade_shot={"0"},
		upgrade_attack_speed={"9"}
	}

	fonts={
		title=love.graphics.newFont("/Fonts/Comfortaa-Regular.ttf",150),
		default=love.graphics.newFont("/Fonts/Comfortaa-Light.ttf",25)
	}

	--spawnpoint
	spawpoint={x=500,y=500}

	--player
	player = {
		x=spawpoint.x,
		y=spawpoint.y,
		xspeed=-1,
		yspeed=-1,
		timespeed=45,
		maxhealth=100,
		health=100,
		damage=5,
		attack_speed=2,
		money=0
	}

	scores={}
	--menu tab/ game tabs
	tab=0

	--asteroids
	asteroids={}

	--Particles--
	--stars
	stars={}
	--fire
	fire={}

	--bullets
	bullets={}

	canshoot=true

	spawn_frecuency=0.2
	spawntimer=0

	attack_timer=0
	--hide the mouse
	love.mouse.setVisible(false)
	
	scale=0
	score=0
end

function love.focus(focus) --pause the game when the window is not active
	paused=not focus
end

function love.update(dt)
	if love.keyboard.isDown(keys.pause) then paused=not paused end
	if paused then return end
	--coordinates used to draw the mouse
	mx,my=resolution.getMousePosition(screen_width,screen_height)
	manageGUI()

	if tab==1 then
	handle_input(dt)
	

	scale=resolution.getScale(screen_width,screen_height)
	
	--manage time
	spawntimer=spawntimer+player.timespeed*dt
	attack_timer=attack_timer+player.timespeed*dt
	if attack_timer>=1/player.attack_speed then canshoot=true attack_timer=0 end
	if spawntimer>=spawn_frecuency then add_objects() score=score+1 spawntimer=0 end

	manage_asteroid(dt)
	particles()
	manage_particles(dt)
	check_collision()


	--update coordinates
	player.y=player.y+player.yspeed
	player.x=player.x+player.xspeed
	if player.x<0 then player.x=screen_width end
	if player.y<0 then player.y=screen_height end
	if player.x>screen_width then player.x=0 end
	if player.y>screen_height then player.y=0 end
	end
end

function love.draw()
	--start tlfres lib
	love.graphics.push()
	resolution.beginRendering(screen_width,screen_height)

	love.graphics.setColor(255,255,255,255)

	effect(function() drawGUI() end)

	if tab==1 then
		effect(function()
			love.graphics.setLineWidth(2)

			love.graphics.setColor(255,255,255)
			for s,star in ipairs(stars) do love.graphics.circle("fill",star.x,star.y,2) end

			love.graphics.setColor(1,0.69,0,0.62)
			for b,asteroid in ipairs(asteroids) do  love.graphics.circle("line",asteroid.x,asteroid.y,asteroid.size) end
			
			for f,fire_particle in ipairs(fire) do love.graphics.setColor(fire_particle.time,fire_particle.time,0) love.graphics.circle("fill",fire_particle.x,fire_particle.y,5) end

			love.graphics.setColor(0,255,0)
			for bulletindex,bullet in ipairs(bullets) do love.graphics.line(bullet.x,bullet.y,bullet.x+10,bullet.y+10) end
	
			--draw the player
			love.graphics.setColor(255,255,255)
			love.graphics.polygon("line",player.x, player.y, player.x+25, player.y+15, player.x+5,player.y+30)
		end)
	end
	--stop using tlfres lib
	resolution.endRendering({255,255,255})
	love.graphics.pop()
end

function handle_input(dt)
	--key handling
	if love.keyboard.isDown(keys.up) then player.yspeed=player.yspeed-dt*2
	elseif love.keyboard.isDown(keys.down) then player.yspeed=player.yspeed+dt*2 end
	if love.keyboard.isDown(keys.left) then player.xspeed=player.xspeed-dt*2
	elseif love.keyboard.isDown(keys.right) then player.xspeed=player.xspeed+dt*2 end

	if love.keyboard.isDown(keys.upgrade_shot) then player.damage=player.damage+1 print(player.damage) end
	if love.keyboard.isDown(keys.upgrade_attack_speed) then player.attack_speed=player.attack_speed+1 print(player.attack_speed) end

	player.timespeed=mx/500+spawn_frecuency/15
	if love.mouse.isDown(keys.shoot) and canshoot then shoot() end
end

function shoot()
	table.insert(bullets,{x=player.x,y=player.y,speed=-400})
	canshoot=false
end

function manage_asteroid(dt)
	for bindex,asteroid in ipairs(asteroids) do
		asteroid.x=asteroid.x+player.timespeed*asteroid.speed*dt
		asteroid.y=asteroid.y+player.timespeed*asteroid.speed*dt
		if asteroid.size<=0 then player.money=player.money+asteroid.money end
		if asteroid.y>screen_height+30 or asteroid.size<=0 then table.remove(asteroids,bindex) end
	end
end

function particles()
	table.insert(fire,{x=player.x+15,y=player.y+23,speed=400,time=0})
end

function manage_particles(dt)
	for f,fire_particle in ipairs(fire) do 
		fire_particle.x=fire_particle.x+player.timespeed*fire_particle.speed*dt
		fire_particle.y=fire_particle.y+player.timespeed*fire_particle.speed*dt
		fire_particle.time=fire_particle.time+10
		if fire_particle.time>50 then table.remove(fire,f) end
	end

	for sindex,star in ipairs(stars) do 
		star.x=star.x+player.timespeed*star.speed*dt
		star.y=star.y+player.timespeed*star.speed*dt
		if star.y>screen_height+30 then table.remove(stars,sindex) end
	end

	for bulletindex,bullet in ipairs(bullets) do 
		bullet.x=bullet.x+player.timespeed*bullet.speed*dt
		bullet.y=bullet.y+player.timespeed*bullet.speed*dt
		if bullet.y<-screen_height then table.remove(bullets,bulletindex) end
	end
end

function add_objects()
	table.insert(asteroids,{x=math.random(-screen_height,screen_height+screen_height/2),y=0,speed=400,size=math.random(1,10)*5,colliding_with_bullet=false,colliding_with_player=false,money=math.random(1,30)})
	table.insert(stars,{x=math.random(-screen_height,screen_height+screen_height/2),y=0,speed=400})
end

function check_collision()
	for ac,asteroid in ipairs(asteroids) do	
			asteroid.colliding_with_player=checkCircularCollision(asteroid.x,asteroid.y,asteroid.size,player.x+10,player.y+15,10)
			if asteroid.colliding_with_player then player.health=player.health-math.floor(asteroid.size/3) table.remove(asteroids,ac) end
			if player.health<=0 and not isdead then die() end

			for bc,bullet in ipairs(bullets) do
				asteroid.colliding_with_bullet=checkCircularCollision(asteroid.x,asteroid.y,asteroid.size,bullet.x,bullet.y,10)
				if asteroid.colliding_with_bullet then asteroid.size=asteroid.size-player.damage table.remove(bullets,bc) end
			end
	end
end

function checkCircularCollision(ax,ay,ar,bx,by,br)
	local dx = bx - ax
	local dy = by - ay
	return dx^2 + dy^2 < (ar + br)^2
end

function die()
	isdead=true
	manage_scores(score)
	restart_game(false)
end

function drawGUI()

	love.graphics.setFont(fonts.default)

	if tab==1 then
		love.graphics.print("Health: "..player.health.."/"..player.maxhealth,30,30,0)
		love.graphics.print("Score: "..score,30,50)
		love.graphics.print("Money: "..player.money.."$",30,70)
		if paused then love.graphics.print("Paused",screen_width/2,screen_height/2,0,1,1) end
	end
	
	if tab==0 then 
		love.graphics.rectangle("line",ui.buttons.play.x,ui.buttons.play.y,ui.buttons.play.width,ui.buttons.play.height)
		love.graphics.print(ui.buttons.play.text,ui.buttons.play.x,ui.buttons.play.y)

		love.graphics.setFont(fonts.title)
		love.graphics.print(ui.text.title.text,ui.text.title.x,ui.text.title.y)
	end

	--draw a mouse
	love.graphics.circle("fill",mx-5,my-5,5)
end

function manageGUI()
	ui.buttons.play.pressed=checkCircularCollision(ui.buttons.play.x,ui.buttons.play.y,30,mx,my,5) and love.mouse.isDown(keys.shoot)
	if ui.buttons.play.pressed then tab=1 end
end

function manage_scores(score)
	table.insert(scores,score)
	table.sort(scores,function(a,b) return a>b end)
	print("--------------")
	print("Score:"..score)
	print("Highscores:")

	for scc,sc in pairs(scores) do
		print(scc.."- "..sc)
	end
	print("--------------")
end

function restart_game(goToMenu)
	score=0
	isdead=false
	asteroids={}
	bullets={}
	stars={}
	player.health=player.maxhealth
	player.xspeed=-1
	player.yspeed=-1
	player.x=spawpoint.x
	player.y=spawpoint.y
	if goToMenu then tab=0 end
end
