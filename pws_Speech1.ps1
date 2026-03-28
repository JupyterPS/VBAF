Add-Type -AssemblyName System.Speech

[int]$guess = 0
[int]$attempt = 0
[int]$number = Get-Random -Minimum 1 -Maximum 100

$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voice.Speak("Ahoy matey! I'm the Dreaded Pirate Robbins, and I have a secret!
              It's a number between 1 and 100. I'll give you 7 tries to guess it.")

do {
    $voice.SpeakAsync("What's your guess?") | Out-Null

    try {
        $guess = Read-Host "What's your guess?"

        if ($guess -lt 1 -or $guess -gt 100) {
            throw
        }
    }
    catch {
        $voice.Speak("Invalid number")
        continue
    }

    if ($guess -lt $number) {
        $voice.Speak("Too low, yee scurry dog!")
    }
    elseif ($guess -gt $number) {
        $voice.Speak("Too high, yee land lubber!")
    }

    $attempt += 1
}
until ($guess -eq $number -or $attempt -eq 7)

if ($guess -eq $number) {
    $voice.Speak("Avast! Yee guessed my secret number, yee did!")
}
else {
    $voice.Speak("Yee out of guesses! Better luck next time, yee matey!
                  My secret number was $number")
}

#________________________________________________________________________________________

#Requires -Version 3.0
Add-Type -AssemblyName System.Speech

$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer

$voice.GetInstalledVoices() | ForEach-Object {
    if ($_.VoiceInfo.Id -match "TTS_MS_(?<culture>\w{2}-\w{2})_(?<name>[^_]+)") {
        $Name = $matches.name
        $Culture = [cultureinfo]$matches.culture | select -expand DisplayName
    }
    else {
        Write-Warning "Couldn't get info from $($_.VoiceInfo.Id)"
        $Name = "something I'm not going to share with you"
        $Culture = "something you're not going to find out"
    }
    $Name = 'Henning reckey'
    $Culture = 'Danish'
    $voice.SelectVoice($_.voiceinfo.name)
    $voice.Speak("Hi, my name is $Name and my speaking style is $Culture")
}


#_______________________________________________________________________________


Add-Type -AssemblyName System.speech
$tts = New-Object System.Speech.Synthesis.SpeechSynthesizer

$count = 0
 Do {
      $count  ++

      # Using an array
$Phrase2 = @("I'm a robot.", 
    "Help, I'm stuck in the machine!", 
    "Please, get me out of here Henning") | Get-Random

$tts.Rate   = 0  # -10 is slowest, 10 is fastest
$tts.Speak($Phrase2)
       
} until($count -eq 10)







