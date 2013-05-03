# Tock Tracker!

A tock is like a pomodoro but 45 minutes instead of 25.

## Rules for beeminding tocks

1. Tag it :smac iff you get TagTime-pinged off task (that counts as -2 tocks!)
2. Try to pick things that take as long as possible without going over 45min
   (it counts as a fractional tock if you finish early, eg, 30min = 2/3)
3. If you do go over 45min then it doesn't matter when you stop the clock or
   whether you tag it done (it counts as 1/3 of a tock regardless)
4. Make sure to tag it :tock when you start and :done if you finish early
5. Tag it :void for a legit interruption or forgetting to stop the timer


## Original contest rules with Danny and Bethany and David Yang

 - each hour that >1 of us does a tock we each put $2 in the pot
 - if you don't finish in 45 minutes you forfeit your ante and get nothing
 - of those remaining, whoever takes *longest* to finish gets the pot
   (future idea: split the pot proportionally to how long each person took)
 - if no one finished in 45 minutes, the pot rolls over for next time
 - you have to mark the tock as :smac if you get tagtime-pinged while off task
 
(original contest was closed and paid on 2007.06.27)

## Installation Instructions

1. Copy settings.pl.template to settings.pl and mutatis mutandis
2. Create a symlink, eg: ln -s prj/tocks/settings.pl ~/.tocksrc
3. Put something like this in your crontab:  
     `00 * * * * $HOME/prj/tocks/launch.pl`  
     `59 8 * * * rm -f $HOME/prj/tocks/.tocklock`

If you want to start tocks manually, you may need to edit out the line 
that starts something like `$ENV{DISPLAY} = ":0.0";`   
(Don't know what that crap is about; only an issue for bsoule.)
