;------------------------------------------------
;
; Atari VCS Game 
; by Dijkstra Liu
;
;------------------------------------------------
	processor 	6502
	include 	vcs.h
	include 	macro.h

;------------------------------------------------
; Constants
;------------------------------------------------
BLACK = #$00
BLUE = #$AE
BROWN = #$2D
WHITE = #$0F
SKY_HEIGHT = #87
PLANE_HEIGHT = #8
L1_NUM = #5
RED = #$40
YELLOW = #$1F
SCORE_DIGIT_HEIGHT = #4
SCORE_DELAY = #16
PURPLE = #$52
BRONZE = #$34
SILVER = #$0A
GOLD = #$1E
SUPER = #$48

ENEMY1Y = #30
ENEMY2Y = #20
ENEMY3Y = #10
;------------------------------------------------
; RAM
;------------------------------------------------
    SEG.U   variables
    ORG     $80

finalScore   .byte
progress  .byte   ;to check the status of the game
begin   .byte
laserStage   .byte
laserPosition   .byte
p0y			.byte
FRAME    .byte

bgcolor		.byte ; background color
skycolor   .byte
frame		.byte  ; frame counter
speed   .byte  ; the moving speed pf the background	0C				
shot    .byte  ; 1 if the enemy get shot and 0 if not
acc    .byte   ; to know the player is acc or not

enemyLT  .byte   ; Enemy life time. Reset Enemy when it got to zero

; score 
p0score		.byte

p0scoreDelay	.byte
p0scoreGfx	ds 2

moving    .byte

PF0_L1    .byte
PF0_L2    .byte
PF0_L3    .byte
PF0_L4    .byte
PF0_L5    .byte
PF0_L6    .byte
PF0_L7    .byte
PF0_L8    .byte


PF1_L1    .byte
PF1_L2    .byte
PF1_L3    .byte
PF1_L4    .byte
PF1_L5    .byte
PF1_L6    .byte
PF1_L7    .byte
PF1_L8    .byte

PF2_L1    .byte
PF2_L2    .byte
PF2_L3    .byte
PF2_L4    .byte
PF2_L5    .byte
PF2_L6    .byte
PF2_L7    .byte
PF2_L8    .byte

sprite0gfx    ds 2  ;pointer to a 16bits location of sprite graphics
p0gfx    .byte
p0pgf1   .byte
p0color		.byte
 ; the y axis the player is

sprite1gfx	ds 2
p1gfx		.byte
p1color		.byte
p1y			.byte
p2y     .byte
p3y			.byte
rush    .byte
keyy    .byte
missileLT  .byte

animIndex .byte
gfx0Index	.byte
enemyGfxIndex	.byte
m0 				.byte
missile0y .byte
velocity  .byte
temp      .byte
displayEnemy  .byte
lasery    .byte
Over    .byte


pfGOgfx   ds 2

	echo [($100 - *)]d, " RAM bytes used"

;------------------------------------------------
; Start of ROM
;------------------------------------------------
	SEG   Bank0
	ORG   $F000       	; 4k ROM start point
	
Start
	CLEAN_START
	lda   #$2C
	sta   skycolor
	jmp   .idle
Begin
	CLEAN_START
	lda  #1
	sta  begin
.idle
			; Clear RAM and Registers
	lda   #$FF      ; initial Sound
	sta   AUDV0
	sta   AUDV1
	lda		#%00000010
	sta		RESMP0		; reset missile 1 to player 1

	lda		#0
	sta		bgcolor
	sta   acc
	sta   Over
	sta   FRAME
	lda		#$06
	sta		COLUPF
	lda		#0
	sta		CTRLPF
	sta   missileLT
	lda   #40
	sta   enemyLT




;------------------------------------------------
; INITIALIZE GAME
;------------------------------------------------
	;Player Stuff
	lda		#25
	sta		p0y    ;initial p0 y position

	lda   #30
	sta   p1y    ;initial p1 y position

	lda   #20
	sta   p2y  

	lda   #10
	sta   p3y  

	ldx   #24
.initRAM
	lda   DataPF0-1,x   ; initial mountains
	sta   PF0_L1-1,x
	dex
	bne   .initRAM

	; initial sprite graphic pointers
	lda   #<SpriteGfx1
	sta   sprite0gfx
	lda		#>SpriteGfx1
	sta		sprite0gfx+1




	lda		#$0F
	sta		COLUP0
	lda   #%00000101
	sta   NUSIZ0    ; graphc *2
	lda   #%00000000
	sta   NUSIZ1


	; initial bg moving speed
	lda   #4
	sta   speed

	lda   #1
	sta   REFP1



;------------------------------------------------
; Vertical Blank
;------------------------------------------------	
MainLoop
	;***** Vertical Sync routine
	inc   FRAME
	lda		#2
	sta  	VSYNC 	; begin vertical sync, hold for 3 lines
	sta  	WSYNC 	; 1st line of vsync
	sta  	WSYNC 	; 2nd line of vsync
	sta  	WSYNC 	; 3rd line of vsync
	lda  	#43   	; set up timer for end of vblank
	sta  	TIM64T
	lda 	#0
	sta  	VSYNC 	; turn off vertical sync - also start of vertical blank

	lda   begin
	bne   .continue1
	jmp   EndCheckShot
.continue1

	lda   progress
	and   #%11111
	cmp   #%10000
	bcc   .day
	lda   #$80
	sta   skycolor
	jmp   .endDay

.day
	lda   #$2C
	sta   skycolor
.endDay


	lda   FRAME
	cmp   #1
	beq   .resetLaserPosition
	jmp   .EndlaserPostion
.resetLaserPosition
	lda   p0y
	sbc   #4
	sta   laserPosition
.EndlaserPostion
	lda   progress
	cmp   #20
	bcc   .setLaserStage0 
	lda   FRAME
	cmp   #1
	bcc   .setLaserStage0 
	cmp   #129
	bcc   .setLaserStage1  
	cmp   #195
	bcc   .setLaserStage2  
	jmp   .setLaserStage0  

.setLaserStage1
	lda   #1
	sta   laserStage       
	jmp   .endLaserStage

.setLaserStage2
	lda   #2
	sta   laserStage      
	jmp   .endLaserStage

.setLaserStage0
	lda   #0
	sta   laserStage       

.endLaserStage


	lda   enemyLT
	cmp   #7
	bcc   .isSetting  
	cmp   #153
	bcs   .isSetting  
	lda   #1       
	sta   displayEnemy
	jmp   .notSetting


.isSetting
    lda   #0      
    sta   displayEnemy
.notSetting

	lda   #0
	sta   AUDV1
	lda   laserStage
	cmp   #0
	beq   .noLaser
	cmp   #1
	beq   .flashLaser
	cmp   #2
	beq   .laserAtt

.laserAtt
	lda   laserPosition
	sta   lasery
	jmp   .endLaserSet

.flashLaser
	lda   FRAME
	and   #%1111
	cmp   #7
	bcc   .laserShow
	lda   #$FF
	sta   lasery
	jmp   .noLaserShow

.laserShow
	lda   laserPosition
	sta   lasery
	lda   #%1100
	sta   AUDC1
	lda   #%0001
	sta   AUDF1
	lda   #$FF
	sta   AUDV1
.noLaserShow	
	jmp   .endLaserSet

.noLaser
	lda   #$FF
	sta   lasery

.endLaserSet


  lda   frame        
	and   #01          
	beq   EvenFrame

OddFrame
	lda   #<EnemyGfx1 
	sta   sprite1gfx
	lda   #>EnemyGfx1 
	sta   sprite1gfx+1
	lda   #0
	sta   animIndex
	jmp   endEvenFrame    


EvenFrame
	lda   #<EnemyGfx  
	sta   sprite1gfx
	lda   #>EnemyGfx  
	sta   sprite1gfx+1
endEvenFrame

	;***** Vertical Blank code goes here
	; clear playfield
	lda		#$00
	sta		PF0
	sta		PF1
	sta		PF2
	sta		bgcolor
	sta   HMP0    ;
	lda		#$0E
	sta		COLUPF
	lda		#%0011000
	sta		CTRLPF
	lda		#$2C
	sta		COLUBK
	lda   #1


;------------------------------------------------
; Enemy Reset
;------------------------------------------------	
	lda   enemyLT
	beq   .resetEnemy
	dec   enemyLT
	beq   .resetEnemy
	lda   acc    ; if acc, the life time should be shorter
	beq   .noSpeed
	dec   enemyLT
	beq   .resetEnemy
.noSpeed
	jmp   .EndResetEnemy

.resetEnemy
	inc   progress
	lda   #0
	sta   shot    ; inistialize all enemy's state
	lda   #$FF
	sta   p1y
	sta   p2y
	sta   p3y
	lda   #160
	sta   enemyLT   ; set the enemy lifetime to 160


	lda   progress
	cmp   #10
	bcc   .level1     ; progress less than 10, jump to level 1
	cmp   #30
	bcc   .level2     ; progress less than 30, jump to level 2
	jmp   .level3

.level1      ; level 1, only one enemy

	lda   p0y   ; set the enemy based on player's location
	cmp   #15
	bcc   .set30     
	cmp   #25
	bcc   .set10   

	lda   #ENEMY2Y      ;set up enemy2
	sta   p2y
	jmp   .storeKeyy

.set30    ; set up enemy1
    lda   #ENEMY1Y     
		sta   p1y
    jmp   .storeKeyy

.set10
    lda   #ENEMY3Y    
		sta   p3y

.storeKeyy
    sta   keyy
		jmp   .EndResetEnemy


.level2
	lda   p0y   ; set the enemy based on player's location
	cmp   #15
	bcc   .set302    
	cmp   #25
	bcc   .set102   

	lda   #ENEMY1Y
	sta   p1y
	lda   #ENEMY2Y       ;set up enemy2
	sta   p2y
	jmp   .storeKeyy2

.set302    ; set up enemy1
		lda   #ENEMY2Y
		sta   p2y
    lda   #ENEMY1Y
		sta   p1y
    jmp   .storeKeyy2

.set102
		lda   #ENEMY2Y
		sta   p2y
    lda   #ENEMY3Y 
		sta   p3y

.storeKeyy2
    sta   keyy
		jmp   .EndResetEnemy


.level3
	lda   #ENEMY3Y
	sta   p3y
	lda   #ENEMY2Y
	sta   p2y
	lda   #ENEMY1Y
	sta   p1y
	lda   p0y   ; set the enemy based on player's location

	cmp   #15
	bcc   .set303    
	cmp   #25
	bcc   .set103   

	lda   #20       ;set up enemy2
	jmp   .storeKeyy3

.set303    ; set up enemy1
    lda   #30     
    jmp   .storeKeyy3

.set103
    lda   #10      

.storeKeyy3
    sta   keyy
		jmp   .EndResetEnemy


.EndResetEnemy

;------------------------------------------------
; Missile Reset
;------------------------------------------------	

	lda   missileLT
	bne   .updateMissile
	lda   #40							; produce missile
	sta   missileLT
	lda   p0y
	sbc   #3
	sta   missile0y
	lda   #0
	sta   RESMP0
	lda		#%11100000
	sta		HMM0  
	jmp   .endMissile
.updateMissile         ; missile is flying, update it's position
	lda   missileLT     
	sbc   #1
	bpl   .finishUpdate   ; If life time is still positive, finishe Update
	lda   #0
.finishUpdate
	sta   missileLT
	lda   missileLT
	bne   .endMissile
	lda		#%00000010
	sta		RESMP0
	lda   #0
	sta   HMM0
.endMissile

CheckShot
	lda   shot
	beq   .noshot
	lda   #<EnemyShotGfx
	sta   sprite1gfx
	lda		#>EnemyShotGfx
	sta		sprite1gfx+1	 
	; lda   #0
	; sta   shot
	jmp   EndCheckShot
.noshot
EndCheckShot

;------------------------------------------------
; Player input
;------------------------------------------------	




CheckResetSwitch
	lda 	#%00000001
	bit 	SWCHB
	bne   .endCheckResetSwitch
	lda   #1
	sta   begin
	jmp 	Begin
.endCheckResetSwitch

	lda   begin
	bne   .continue2
	jmp   .skipP1ScoreDelayDec
.continue2

	inc		frame
	lda		frame
	cmp   speed
	beq   .continueInput

	jmp   EndScroll

.continueInput
	lda   #0
	sta   moving
	lda   #0
	sta   frame
	inc   velocity

CheckJoy0Fire
	lda		#%10000000			; test this bit
	bit		INPT4 				; latch for joystick 0 trigger (joy1 is on INPT5)
	bne		.endCheckJoy0Fire
	lda   p0score
	beq   .endCheckJoy0Fire
	lda		p0scoreDelay
	bne		.endDecScore   ; if scoreDelay is not Zero, just end
	dec   p0score
	lda		#SCORE_DELAY
	sta		p0scoreDelay	
.endDecScore
	lda   #2
	sta   speed
	sta   acc
	jmp   CheckJoy0Up
.endCheckJoy0Fire
	lda   #4
	sta   speed
	lda   #0
	sta   acc



CheckJoy0Up
	lda   #%00010000
	bit   SWCHA
	bne   .endJoy0Up

	lda   p0y
	cmp   #36
	beq   .endJoy0Up
	inc   p0y
.endJoy0Up

CheckJoy0Down
	lda   #%00100000
	bit   SWCHA
	bne   .endJoy0Down

	lda   p0y
	cmp   #13
	beq   .endJoy0Down
	dec   p0y
.endJoy0Down



CheckJoy0Left
	lda		#%01000000
	bit		SWCHA
	bne		.endCheckJoy0Left
	lda   #2       ; load dec animation
	sta   animIndex
	lda   #%01000000
	sta   HMP0
	lda   #1
	sta   moving
.endCheckJoy0Left

CheckJoy0Right
	lda 	#%10000000
	bit 	SWCHA
	bne		.endCheckJoy0Right
	lda   #1       ; load acc animation
	sta   animIndex
	lda   #%11000000
	sta   HMP0
	lda   #1
	sta   moving
.endCheckJoy0Right
;------------------------------------------------
; Animation
;------------------------------------------------

	ldx  animIndex  
	lda  SpriteFrames,x   
	sta  sprite0gfx
	lda  #>SpriteGfx
	sta  sprite0gfx+1
	lda   acc
	bne   .acceleration
	lda   #%00010000    ; left enemy move left
	sta   HMP1

	jmp   ScrollPlayfieldLeft
.acceleration
	ldx   #3
	lda  SpriteFrames,x   
	sta  sprite0gfx
	lda  #>SpriteGfx
	sta  sprite0gfx+1
	lda   #$AE
	sta   p0color
	lda   #%00100000
	sta   HMP1

ScrollPlayfieldLeft
	ldx   #8
.scrollPlayfieldLeft
	lsr   #PF2_L1-1,x
	rol   #PF1_L1-1,x
	ror		#PF0_L1-1,x
	lda   #PF0_L1-1,x
	and   #%00001000
	beq   .scrollLeft1
	lda   #PF2_L1-1,x
	ora   #%10000000
	sta   #PF2_L1-1,x

.scrollLeft1
	dex
	bne   .scrollPlayfieldLeft
.endScrollLeft
EndScroll

	lda   frame
	and   #$01
	beq   notflash
	lda   moving
	bne   notflash
	ldx   #4
	lda   SpriteFrames,x   
	sta   sprite0gfx
	lda   #>SpriteGfx
	sta   sprite0gfx+1
notflash

;------------------------------------------------
; Collision
;------------------------------------------------	

	lda   laserStage
	cmp   #2         
	bne   .laserNotAtt  

	lda   p0y
	sec               
	sbc   laserPosition    
	cmp   #8       
	bcc   .collisionLaser
	jmp   .laserNotAtt

.collisionLaser
	lda  acc
	bne  .laserNotAtt
	lda  #1
	sta  Over

.laserNotAtt:


	lda   CXM0P
	and   #%10000000      ; Mask everything but D6
	beq   .noCollisionM0P1
	lda   missile0y
	clc
	adc   #05
	cmp   keyy
	bcc   .setshottozero

	lda   missile0y
	sec
	sbc   #05
	cmp   keyy
	bcs   .setshottozero

	lda   #01
	sta   shot
	jmp   Done

.setshottozero
	lda   #0
	sta   shot
	lda   #1
	sta   missileLT
	lda   #%1000
	sta   AUDC0
	sta   AUDF0
	jmp   .endScore

Done
	lda   #1
	sta   missileLT


.scoreP0
	lda		p0scoreDelay
	bne		.endScore
	lda   p0score
	cmp   #7
	beq   EndAddScore
	lda   #%1111
	sta   AUDC0
	inc		p0score				; Increment the score
EndAddScore
	lda		#SCORE_DELAY
	sta		p0scoreDelay
.endScore
	bne   EndCheckCollision
.noCollisionM0P1

	lda		CXPPMM
	and		#$80
	beq   .noCollisionPPMM
	lda   #%1000
	sta   AUDC0
	sta   AUDF0
	lda   #1
	sta   shot
	lda   acc
	bne   EndCheckCollision
	lda   #1
	sta   Over
	jmp   EndCheckCollision
.noCollisionPPMM
	lda   #0
	sta   AUDC0
	sta   AUDF0
EndCheckCollision 

ScoreDelay
	; Decay the score delay as needed
	dec		p0scoreDelay				; decrement the delay counter
	bpl		.skipP1ScoreDelayDec		; branch if positive (if negative flag clear), that is, if we didn't decrement past 0
	lda		#0							; otherwise reset to 0
	sta		p0scoreDelay
	; you could also do this with a second counter if we were counting two scores (this sample code doesn't)
.skipP1ScoreDelayDec


; ===================
; SET UP SCORE GRAPHICS
; ===================


.waitForVBlank
	lda		INTIM
	bne		.waitForVBlank
	sta		WSYNC
	sta   HMOVE
	sta   CXCLR					; clear all collision
	sta		VBLANK

;------------------------------------------------
; Kernel
;------------------------------------------------	
DrawScreen

	lda		#$00
	sta		COLUBK
	sta   WSYNC

	lda   Over
	cmp   #0
	beq   .ContinueGame
	jmp   .GameOver
.ContinueGame
Energy
	sta   WSYNC
	nop
	dey
	ldy   #4
.bar
	lda		#$88
	sta		COLUBK
	ldx   p0score
	beq   .endEnergy
.startEnergy
	nop
	dex
	bne   .startEnergy
.endEnergy
  lda   skycolor
	sta		COLUBK
	sta   WSYNC
	dey
	bne   .bar

	lda		skycolor
	sta		COLUBK

	ldx   #36
.sunset

	
	; draw sprite and color
	lda 	p0gfx     ; load P0 sprite
	sta   GRP0			; P0 sprite
	lda		p0color		; same for the color
	sta		COLUP0    ; color the player

	lda   p1gfx
	sta   GRP1
	lda   p1color
	sta   COLUP1
	lda   m0
	sta   ENAM0

	
	lda		#0
	sta		p1gfx
	; The first sprite
	cpx   p0y
	bne   .loadSprite0
	lda	  #8   ;sprite height
	sta   gfx0Index
.loadSprite0
  lda   gfx0Index
  cmp   #$FF
	beq   .noSprite0
	tay
	lda   (sprite0gfx),y
	sta    p0gfx
	lda    acc
	bne    .endcolor
	lda    PlaneColor,y
	sta    p0color
.endcolor
	dec    gfx0Index
	jmp   .endSprite0
.noSprite0
  lda   #0
	sta   p0gfx
.endSprite0
	lda   displayEnemy
	beq   .noStartEnemySprite
	cpx   p1y
	beq   .startEnemySprite
	cpx   p2y
	beq   .startEnemySprite
	cpx   p3y
	beq   .startEnemySprite
	jmp   .noStartEnemySprite


.startEnemySprite
	lda   #3
	sta   enemyGfxIndex
	cpx   keyy
	beq   .isKey
	lda   #BLACK
	sta   p1color
	jmp   .notKey
.isKey
	lda   #PURPLE
	sta   p1color
.notKey

.noStartEnemySprite
	lda   enemyGfxIndex
	cmp   #$FF
	beq   .noEnemySprite

	tay
	lda   (sprite1gfx),y
	sta   p1gfx
	dec   enemyGfxIndex
	jmp   .endEnemySprite

.noEnemySprite
	lda   #0
	sta   p1gfx
.endEnemySprite


	cpx   lasery
	sta   WSYNC
	beq   .laser
	lda		skycolor
	sta		COLUBK
	jmp   .endLaser
.laser
	lda   #RED
	sta   COLUBK
.endLaser

	; Missile
	lda   #0
	cpx   missile0y
	bne   .noMissile0
	lda   #%00000010
.noMissile0
	sta   m0
	dex
	sta		WSYNC
	beq   .skip
	jmp   .sunset
.skip

	ldx		#8
	lda		#$00
	sta		COLUPF
.city	
	lda   skycolor
	cmp   #$80
	bne   .daylight
	lda		Nightlight-1,x
	jmp   .storelight
.daylight
	lda		Sunset-1,x
.storelight
	sta		COLUBK
	lda		PF0_L1 - 1,x
	sta		PF0
	lda		PF1_L1 - 1,x
	sta		PF1
	lda		PF2_L1 - 1,x
	sta		PF2
	dex
	sta		WSYNC
	sta		WSYNC
	sta		WSYNC
	bne		.city
	
	lda   #0
	sta		PF0
	sta		PF1
	sta		PF2

	ldx		#3
.wave
	lda		#$88
	sta		COLUBK
	dex
	sta   WSYNC
	bne 	.wave

	lda   progress
	cmp 	#30
	bcc   .52
	ldx		#51
	jmp   .ocean
.52
	ldx		#52
.ocean
	lda		#$72
	sta   COLUBK
	dex
	sta   WSYNC
	bne   .ocean
	jmp   .notGameOver
	

.GameOver
	lda   finalScore
	cmp   #0
	beq   .loadFinal
	jmp   .notload
.loadFinal
	lda   progress
	sta   finalScore
.notload
	lda   #0
	sta   AUDC1
	sta   AUDV1
	sta   AUDF1
	lda   #244
	sta   FRAME

	ldx   #50
.black1
	sta   WSYNC
	dex
	bne   .black1

	ldx   #7
.GAMEscreen
	ldy   #3
.aline
	lda   GameOverGfxG-1,x
	sta   PF1
	lda   GameOverGfxA-1,x
	sta   PF2
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda   GameOverGfxM-1,x
	sta   PF1
	lda   GameOverGfxE-1,x
	sta   PF2
	sta   WSYNC
	dey
	bne   .aline
	dex
	bne   .GAMEscreen
	lda   #0
	sta   PF1
	sta   PF2

	ldx   #20
.black2
	sta   WSYNC
	dex
	bne   .black2

	ldx   #7
.Overscreen
	ldy   #3
.bline
	lda   GameOverGfxO-1,x
	sta   PF1
	lda   GameOverGfxV-1,x
	sta   PF2
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda   GameOverGfxE1-1,x
	sta   PF1
	lda   GameOverGfxR-1,x
	sta   PF2
	sta   WSYNC
	dey
	bne   .bline
	dex
	bne   .Overscreen
	lda   #0
	sta   PF1
	sta   PF2

	ldx   #29
.black3
	sta   WSYNC
	dex
	bne   .black3

	lda   finalScore
	cmp   #20
	bcc   .bronze
	cmp   #40
	bcc   .silver
	cmp   #70
	bcc   .gold
	lda   #SUPER
	jmp   .endMedalColor
.bronze
	lda   #BRONZE
	jmp   .endMedalColor
.silver
	lda   #SILVER
	jmp   .endMedalColor
.gold
	lda   #GOLD
.endMedalColor
	sta   COLUPF
	ldx   #8
.medalScreen
	ldy   #5

.cline
	lda   MedalGfx-1,x
	sta   PF1
	sta   WSYNC
	dey
	bne   .cline
	dex
	bne   .medalScreen
	lda   #0
	sta   PF1
	sta   PF2

	ldx   #11
.black4
	sta   WSYNC
	dex
	bne   .black4

.notGameOver
;------------------------------------------------
; Overscan
;------------------------------------------------
	lda		#%01000010
	sta		WSYNC
	sta		VBLANK
    lda		#36
    sta		TIM64T

	;***** Overscan Code goes here
	lda		#0
	sta		GRP0
	sta		GRP1

.waitForOverscan
	lda     INTIM
	bne     .waitForOverscan

	jmp		MainLoop


;------------------------------------------------
; Subroutines
;------------------------------------------------


;------------------------------------------------
; ROM Tables
;------------------------------------------------
	;***** ROM tables go here
DataPF0
	.byte	#%01111111
	.byte	#%00111110
	.byte	#%00111110
	.byte	#%00111100
	.byte	#%00011000
	.byte	#%00011000
	.byte	#%00011000
	.byte	#%00011000

DataPF1
	.byte	#%11111000
	.byte	#%01111000
	.byte	#%00110000
	.byte	#%00100000
	.byte	#%00000000
	.byte	#%00000000
	.byte	#%00000000
	.byte	#%00000000

DataPF2	
	.byte	#%00111111
	.byte	#%00011111
	.byte	#%00001110
	.byte	#%00001100
	.byte	#%00001000
	.byte	#%00000000
	.byte	#%00000000
	.byte	#%00000000


Sunset
	.byte	#$3C
	.byte	#$3C 
	.byte	#$1C
	.byte	#$1C
	.byte	#$2A
	.byte	#$2A
	.byte	#$2C
	.byte	#$2C
	
Nightlight
	.byte	#$80
	.byte	#$80 
	.byte	#$84
	.byte	#$84
	.byte	#$8A
	.byte	#$8A
	.byte	#$8E
	.byte	#$8E

PlaneColor
	.byte	#$0C
	.byte	#$34
	.byte	#$00
	.byte	#$0E
	.byte	#$34
	.byte	#$0E
	.byte	#$00
	.byte	#$34
	.byte	#$0C


	align 256
SpriteGfx
SpriteGfx1
	.byte #%01111100
	.byte #%00100000
	.byte #%11100000
	.byte #%01111100
	.byte #%01111111
	.byte #%01111100
	.byte #%11100000
	.byte #%00100000
	.byte #%01111100
SpriteGfx2
	.byte #%00000000
	.byte #%01111100
	.byte #%11100000
	.byte #%01111100
	.byte #%11111111
	.byte #%01111100
	.byte #%11100000
	.byte #%01111100
	.byte #%00000000
SpriteGfx3
	.byte #%01111100
	.byte #%01000000
	.byte #%11100000
	.byte #%01111100
	.byte #%01111111
	.byte #%01111100
	.byte #%11100000
	.byte #%01000000
	.byte #%01111100
SpriteGfx4
	.byte #%00000000
	.byte #%00000000
	.byte #%11111100
	.byte #%01111110
	.byte #%11111111
	.byte #%01111110
	.byte #%11111100
	.byte #%00000000
	.byte #%00000000
SpriteGfx5
	.byte #%01111100
	.byte #%00100000
	.byte #%11100000
	.byte #%01111100
	.byte #%11111111
	.byte #%01111100
	.byte #%11100000
	.byte #%00100000
	.byte #%01111100

SpriteFrames
	.byte   <SpriteGfx1
	.byte   <SpriteGfx2
	.byte   <SpriteGfx3
	.byte   <SpriteGfx4
	.byte   <SpriteGfx5

EnemyGfx

	.byte #%00000000
	.byte #%00111100
	.byte #%11110011
	.byte #%00111100

EnemyGfx1
	.byte #%00000000
	.byte #%00111100
	.byte #%11110000
	.byte #%00111100


EnemyShotGfx

	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000

GameOverGfxG
	.byte #%00111000
	.byte #%01000100
	.byte #%01001100
	.byte #%01000000
	.byte #%01000100
	.byte #%00111000
	.byte #%00000000
	.byte #%00000000
GameOverGfxA
	.byte #%01000100
	.byte #%01000100
	.byte #%01111100
	.byte #%01000100
	.byte #%01000100
	.byte #%00111000
	.byte #%00000000
	.byte #%00000000
GameOverGfxM
	.byte #%01000100
	.byte #%01000100
	.byte #%01000100
	.byte #%01010100
	.byte #%01101100
	.byte #%01000100
	.byte #%00000000
	.byte #%00000000
GameOverGfxE
	.byte #%00111100
	.byte #%00000100
	.byte #%00011100
	.byte #%00000100
	.byte #%00000100
	.byte #%00111100
	.byte #%00000000
	.byte #%00000000
GameOverGfxE1
	.byte #%01111100
	.byte #%01000000
	.byte #%01111000
	.byte #%01000000
	.byte #%01000000
	.byte #%01111100
	.byte #%00000000
	.byte #%00000000

GameOverGfxO
	.byte #%00111000
	.byte #%01000100
	.byte #%01000100
	.byte #%01000100
	.byte #%01000100
	.byte #%00111000
	.byte #%00000000
	.byte #%00000000

GameOverGfxV
	.byte #%00010000
	.byte #%00101000	
	.byte #%00101000
	.byte #%00101000	
	.byte #%01000100
	.byte #%01000100
	.byte #%00000000
	.byte #%00000000

GameOverGfxR
	.byte #%00100100
	.byte #%00100100	
	.byte #%00011100
	.byte #%00100100	
	.byte #%00100100
	.byte #%00011100
	.byte #%00000000
	.byte #%00000000

MedalGfx

	.byte #%01000100
	.byte #%01000100	
	.byte #%00101000
	.byte #%00111000	
	.byte #%01111100
	.byte #%01111100
	.byte #%01111100
	.byte #%00111000
;------------------------------------------------
; Interrupt Vectors
;------------------------------------------------
	echo [*-$F000]d, " ROM bytes used"
	ORG    $FFFA
	.word  Start         ; NMI
	.word  Start         ; RESET
	.word  Start         ; IRQ
    
	END