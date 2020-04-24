# Sonic Pi Euclidean Drum Machine
use_bpm 105
set_volume! 3
editQuantisation = 1 # bars to quantise code edits to

"" " Hat Settings " ""
hatRate = 2 # 1 = every 1/16, 2 = every 1/8 etc...
numberOfOpenHats = 1  #3  #2  #2  #3  #2 #3
hatPatternLength = 8 #11 #11 #10 #10 #5 #8
hatOffset = 2
##| hatRotate = hatOffset - 1
hatRotate = 2
offbeat = false
##| offbeat = true
muteHat = false
##| muteHat = true

"" " Kick & Snare Settings " ""
numberOfKicks = 3
kickPatternLength = 10
kickRotate = 3
muteKick = false
##| muteKick = true

numberOfSnares = 5
snarePatternLength = 16
snareRotate = 2
snareOffset = 3
muteSnare = false
##| muteSnare = true

"" " Master Clock " ""
rate = 1 # speed, increase slows
patternLength = 2 # bars to reset clocks at

dynamicsArray = [0.9, 0.45, 0.66, 0.5, 0.85, 0.4, 0.7, 0.4].ring
##| dynamicsArray = [1, 0.7, 0.85, 0.65, 0.95, 0.75, 0.9, 0.65].ring

###### Rhythm patterns ######
###
# make these a map returned by function, whose input is map of settings
# eg,
# ##| rhythmicPatterns = generateSpreadPatterns(mySettingMap)
###
hatPattern = spread(numberOfOpenHats, hatPatternLength, rotate: hatRotate)
kickPattern = spread(numberOfKicks, kickPatternLength, rotate: kickRotate)
snarePattern = spread(numberOfSnares, snarePatternLength, rotate: snareRotate)

### Randomisation settings - dynamics & hat envs ###
randAmt = 0.05
randHigh = 1 + randAmt
randLow = 1 - randAmt
timingAmt = 0.000025

live_loop :avalanche do
  ### TODO
  
  # live_loop :avalanche should be a function, individual drums in own threads
  # threads should have own timing randomisation
  # helper trigger functions for each voice
  # aim for one function - avalanche(mySettingsMap) taking one map as input
  # presets can be maps returned from functions. position below editable map at top of buffer to override
  # eg,
  # mySettingsMap = myTechnoFunction(influenceWithVariables?, chance?)
  # mySettingsMap = myJazzFunction(myVar, anotherVar)
  # define a default map and function, which myJazzFunction() etc. calls as start point
  # run avalanche() in live loop with any fx / automation
  # do some basic fills
  ###
  
  (editQuantisation * 16).times do
    
    ### RESET / CRASH ###
    ###
    # should be a helper function
    # Enable an overhead (in hat module) on reset if fill = true
    ###
    if look % (patternLength * 16) == 0 && look != 1
      puts "resetting all ticks"
      tick_reset_all
      tick_set(1)
      hatCount = tick(:hat)
      snareCount = tick(:snare)
      puts "hatCount: #{hatCount}, snareCount: #{snareCount}, masterClock: #{look}"
      ##| sample :glitch_perc4, rate: 2, amp: 0.8
      playSplash(0.6)

      
    end
    
    masterClock = tick
    
    
    ### KICK ###
    if !muteKick
      if kickPattern[ masterClock - 1 ]
        kickCount = tick(:kick)
        if (kickCount % (numberOfKicks * 2) == 0 && kickCount != 0) ||
            (kickCount >= numberOfKicks && numberOfKicks % 2 != 0) ||
            (kickCount >= numberOfKicks && kickPatternLength % 2 != 0)
          tick_reset(:kick)
          puts "resetting kick count"
          kickCount = tick(:kick)
        end
        kickDynamic = dynamicsArray[kickCount]
        playKick(kickDynamic)
        puts "Kick"
      end
    end
    
    ### SNARE ###
    if !muteSnare
      snareCount = tick(:snare)
      if snarePattern[ snareCount + snareOffset ]
        puts "snare"
        with_fx :distortion, amp: 0.2,
        distort: 0.75 * rrand(randLow, randHigh), mix: 0.8 * rrand(randLow, randHigh) do
          ##| snareDynamic = dynamicsArray[snareCount]
          ##| playSnare(snareDynamic)
          
          sample :drum_snare_hard,
            cutoff: 130 * rrand(0.92, 1.00) * ((0.2 * dynamicsArray.look(offset: -1)) + 0.8),
            rate: 1 * rrand(0.991, 1.009) * ((0.08 * dynamicsArray.look(offset: -1)) + 0.92),
            attack: 0.0025 * rrand(0.9, 1.1),
            amp: 0.25 * dynamicsArray.look(offset: -1) * rrand(0.9, 1.1)
        end
      end
    end
    
    ### HAT ###
    if !muteHat
      
      if offbeat
        lookOffset = 1
        hatRate = 4
      else
        lookOffset = -1
      end
      
      if (masterClock + lookOffset) % hatRate == 0
        hatCount = tick(:hat)
        ##| puts "hatCount: #{hatCount}"
        if hatPattern[ hatCount + hatOffset ]
          puts "Open Hat"
          sample :drum_cymbal_open,
            cutoff: 130 * rrand(0.995, 1.00) * ((0.2 * dynamicsArray.look(:hat)) + 0.8),
            rate: 1 * rrand(0.995, 1.005) * ((0.03 * dynamicsArray.look(:hat)) + 0.97),
            attack: 0.0025 * rrand(0.9, 1.1),
            finish: hatRate * 0.085 * rrand(randLow, randHigh),
            release: hatRate * 0.25 * rrand(randLow, randHigh),
            amp: 0.4 * dynamicsArray.look(:hat) * rrand(0.9, 1)
        else
          sample :drum_cymbal_closed,
            cutoff: 130 * rrand(0.995, 1.00) * ((0.2 * dynamicsArray.look(:hat)) + 0.8),
            rate: 1 * rrand(0.995, 1.005) * ((0.04 * dynamicsArray.look(:hat)) + 0.96),
            attack: 0.0025 * rrand(0.9, 1.1),
            attack: 0.005 * rrand(randLow, randHigh),
            finish: rrand(0.75, 1),
            release: rrand(0.01, 0.05),
            amp: 0.45 * dynamicsArray.look(:hat) * rrand(0.8, 1.2)
        end
      end
    end
    sleep (rate * 0.25) + rrand(-timingAmt, timingAmt)
  end
end

### TO DO ###

# set clock to 24 ppq
