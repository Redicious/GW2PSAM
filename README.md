Guild Wars 2 Addons Manager is a simple script that lets you update addons for Guild Wars 2.
Note that Guild Wars 2 has neither explicitly denied nor allowed the addons that are installed by the script. That means, they are OK'ish to use. Only OK'ish, because they can't control future updates of the addons and therefore can't give a green light.

Why? At the time I started this, there weren't any open source Addon Managers for Guild Wars 2 - and Guildmates asked me to share this script, so I had to make it more usable for others... But now there are other tools available and I recommend using them instead!


You are sure you want to proceed? Really?

Ok... Here is some Information for noobs how to get it running.
You have multiple options on running this script. But I didn't came up with a waterproof solution yet. Following you will find the the different solutions. If you wear a Tinfoil hat, then solution E1/E3 might be the best for you.
If you trust me and have trouble with A and B, use D.

A. Download & Execute everytime.
1. Open a powershell
2. paste "(iwr https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/-/raw/master/Gw2-AddonsManager.ps1).content | iex; GW2AddonManager" into the shell and press enter.
3. Have fun

B. Download via PowerShell and add Shortcuts to your Desktop
1. Open a powershell
2. paste "(iwr https://gitlab.deep-space-nomads.com/Redicious/guild-wars-2-addons-manager/-/raw/master/Gw2-AddonsManager.ps1).content | iex; GW2AddonManager" into the shell and press enter.
3. In the Menu, select the option for creating the Shortcut you want.
4. Use the Shortcut the next time

C. Download the file and run it with powershell
This might need changes to your Execution Policy - more infos here: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1
1. Download Gw2-AddonsManager.ps1 
2. Run the Gw2-AddonsManager.ps1 in a PowerShell
3. Call the manager via "GW2AddonManager"

D. Download the .exe and use it
Note: This might make trouble with your antivirus... But you can whitelist the .exe
Note2: has no autoupdate feature yet
1. Download the .exe
2. Start the .exe

E. Clone the Repo
Note: I don't go into detail how Git works and what stuff could go wrong - google is your friend.

E1. Use the script
1. Clone this Repository.
2. Run the Gw2-AddonsManager.ps1 in a shell
3. Call the manager via "GW2AddonManager"

E2. Use the Bin
1. Clone this Repository.
2. Run the Gw2-AddonsManager.exe in a shell

E3. Adjust Stuff, if you want to
1. Clone this Repository.
2. Do your changes
3. Run bin/_compile.ps1 (with NoExe Param, if you don't want to create an .exe-file)
4. Go To E1 or R2, whatever you like more
